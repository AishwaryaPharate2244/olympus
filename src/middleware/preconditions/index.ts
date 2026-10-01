/**
 * @module
 * Preconditions Middleware for Hono.
 */

import type { Context } from '../../context'
import type { Env, MiddlewareHandler } from '../../types'

/**
 * Validators describing the current representation of the target resource.
 */
export type PreconditionsValidators = {
  /**
   * The current entity-tag, e.g. `"abc"` or `W/"abc"`.
   */
  etag?: string
  /**
   * The last modification time, as a `Date` or an IMF-fixdate string.
   */
  lastModified?: Date | string
}

/**
 * Describes the current representation of the target resource.
 * Return `null` when no representation exists.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type PreconditionsDescriber<E extends Env = any, P extends string = string> = (
  c: Context<E, P>
) => PreconditionsValidators | null | Promise<PreconditionsValidators | null>

type EntityTag = {
  weak: boolean
  // The opaque-tag, including the surrounding double quotes.
  opaque: string
}

type Representation = {
  etag: string | undefined
  tag: EntityTag | undefined
  // Milliseconds since the epoch, floored to whole seconds.
  time: number | undefined
}

const ENTITY_TAG_REGEXP = /^(W\/)?("[^"]*")$/

const IMF_FIXDATE_REGEXP =
  /^(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun), (\d{2}) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$/

const DAY_NAMES = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
const MONTH_NAMES = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
]

const isSafeMethod = (method: string): boolean =>
  method === 'GET' || method === 'HEAD' || method === 'QUERY'

const presentHeader = (c: Context, name: string): string | undefined => {
  const value = c.req.header(name)
  if (value === undefined) {
    return undefined
  }
  const trimmed = value.trim()
  return trimmed === '' ? undefined : trimmed
}

const parseEntityTag = (value: string): EntityTag | undefined => {
  const match = ENTITY_TAG_REGEXP.exec(value)
  return match ? { weak: match[1] !== undefined, opaque: match[2] } : undefined
}

// Splits on commas outside of double quotes and parses each member.
// Members that are not entity-tags are dropped.
const parseEntityTagList = (value: string): EntityTag[] => {
  const members: string[] = []
  let start = 0
  let quoted = false
  for (let i = 0; i < value.length; i++) {
    const ch = value[i]
    if (ch === '"') {
      quoted = !quoted
    } else if (ch === ',' && !quoted) {
      members.push(value.slice(start, i))
      start = i + 1
    }
  }
  members.push(value.slice(start))

  const tags: EntityTag[] = []
  for (const member of members) {
    const tag = parseEntityTag(member.trim())
    if (tag) {
      tags.push(tag)
    }
  }
  return tags
}

const isLeapYear = (year: number): boolean =>
  (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0

const DAYS_IN_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

const daysInMonth = (year: number, month: number): number =>
  month === 1 && isLeapYear(year) ? 29 : DAYS_IN_MONTH[month]

/**
 * Parses an IMF-fixdate (RFC 9110, Section 5.6.7). Obsolete formats are rejected.
 * The weekday is not checked against the date.
 */
const parseImfFixdate = (value: string): number | undefined => {
  const match = IMF_FIXDATE_REGEXP.exec(value)
  if (!match) {
    return undefined
  }
  const day = Number(match[1])
  const month = MONTH_NAMES.indexOf(match[2])
  const year = Number(match[3])
  const hour = Number(match[4])
  const minute = Number(match[5])
  const second = Number(match[6])
  // RFC 9110 allows a leap second (60).
  if (day < 1 || day > daysInMonth(year, month) || hour > 23 || minute > 59 || second > 60) {
    return undefined
  }
  // `Date.UTC` maps years 0 through 99 to the 1900s, so set the full year explicitly.
  const date = new Date(0)
  date.setUTCFullYear(year, month, day)
  date.setUTCHours(hour, minute, second, 0)
  return date.getTime()
}

const isUsableTime = (time: number): boolean => {
  if (!Number.isFinite(time)) {
    return false
  }
  const year = new Date(time).getUTCFullYear()
  return year >= 0 && year <= 9999
}

const toTime = (value: unknown): number | undefined => {
  let time: number | undefined
  if (value instanceof Date) {
    const ms = value.getTime()
    time = Number.isNaN(ms) ? undefined : Math.floor(ms / 1000) * 1000
  } else if (typeof value === 'string') {
    time = parseImfFixdate(value.trim())
  }
  return time !== undefined && isUsableTime(time) ? time : undefined
}

const pad = (value: number, length: number): string => String(value).padStart(length, '0')

const formatImfFixdate = (time: number): string => {
  const date = new Date(time)
  return `${DAY_NAMES[date.getUTCDay()]}, ${pad(date.getUTCDate(), 2)} ${
    MONTH_NAMES[date.getUTCMonth()]
  } ${pad(date.getUTCFullYear(), 4)} ${pad(date.getUTCHours(), 2)}:${pad(
    date.getUTCMinutes(),
    2
  )}:${pad(date.getUTCSeconds(), 2)} GMT`
}

const toRepresentation = (
  validators: PreconditionsValidators | null | undefined
): Representation | undefined => {
  if (validators == null) {
    return undefined
  }
  const etag = typeof validators.etag === 'string' ? validators.etag.trim() : undefined
  const tag = etag === undefined ? undefined : parseEntityTag(etag)
  return {
    etag: tag ? etag : undefined,
    tag,
    time: toTime(validators.lastModified),
  }
}

// If-Match uses the strong comparison function.
const evaluateIfMatch = (header: string, rep: Representation | undefined): boolean => {
  if (header === '*') {
    return rep !== undefined
  }
  const current = rep?.tag
  if (!current || current.weak) {
    return false
  }
  return parseEntityTagList(header).some((tag) => !tag.weak && tag.opaque === current.opaque)
}

// If-None-Match uses the weak comparison function.
const evaluateIfNoneMatch = (header: string, rep: Representation | undefined): boolean => {
  if (header === '*') {
    return rep === undefined
  }
  const current = rep?.tag
  if (!current) {
    return true
  }
  return !parseEntityTagList(header).some((tag) => tag.opaque === current.opaque)
}

/**
 * Preconditions Middleware for Hono.
 *
 * Evaluates `If-Match`, `If-None-Match`, `If-Modified-Since`, and
 * `If-Unmodified-Since` (RFC 9110, Section 13) against the validators returned
 * by `describe`, and responds with `304 Not Modified` or
 * `412 Precondition Failed` when a precondition fails.
 *
 * `describe` is called at most once per request, and only when the request
 * carries a usable precondition header.
 *
 * @param {PreconditionsDescriber} describe - Returns the current validators of the target resource, or `null` when it does not exist.
 * @returns {MiddlewareHandler} The middleware handler function.
 *
 * @example
 * ```ts
 * const app = new Hono()
 *
 * app.put(
 *   '/posts/:id',
 *   preconditions(async (c) => {
 *     const post = await getPost(c.req.param('id'))
 *     return post ? { etag: post.etag, lastModified: post.updatedAt } : null
 *   }),
 *   async (c) => {
 *     // Only reached when the client's preconditions hold.
 *     return c.json(await updatePost(c.req.param('id'), await c.req.json()))
 *   }
 * )
 * ```
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const preconditions = <E extends Env = any, P extends string = string>(
  describe: PreconditionsDescriber<E, P>
): MiddlewareHandler<E, P> => {
  return async function preconditions(c, next) {
    const method = c.req.method
    const ifMatch = presentHeader(c, 'If-Match')
    const ifNoneMatch = presentHeader(c, 'If-None-Match')

    let ifUnmodifiedSince: number | undefined
    if (ifMatch === undefined) {
      const value = presentHeader(c, 'If-Unmodified-Since')
      ifUnmodifiedSince = value === undefined ? undefined : parseImfFixdate(value)
    }

    let ifModifiedSince: number | undefined
    if (ifNoneMatch === undefined && isSafeMethod(method)) {
      const value = presentHeader(c, 'If-Modified-Since')
      ifModifiedSince = value === undefined ? undefined : parseImfFixdate(value)
    }

    if (
      ifMatch === undefined &&
      ifNoneMatch === undefined &&
      ifUnmodifiedSince === undefined &&
      ifModifiedSince === undefined
    ) {
      await next()
      return
    }

    const rep = toRepresentation(await describe(c))

    const fail = (status: 304 | 412) => {
      if (rep?.etag !== undefined) {
        c.header('ETag', rep.etag)
      }
      if (rep?.time !== undefined) {
        c.header('Last-Modified', formatImfFixdate(rep.time))
      }
      return c.body(null, status)
    }

    if (ifMatch !== undefined) {
      if (!evaluateIfMatch(ifMatch, rep)) {
        return fail(412)
      }
    } else if (ifUnmodifiedSince !== undefined) {
      if (rep?.time !== undefined && rep.time > ifUnmodifiedSince) {
        return fail(412)
      }
    }

    if (ifNoneMatch !== undefined) {
      if (!evaluateIfNoneMatch(ifNoneMatch, rep)) {
        return fail(isSafeMethod(method) ? 304 : 412)
      }
    } else if (ifModifiedSince !== undefined) {
      if (rep?.time !== undefined && rep.time <= ifModifiedSince) {
        return fail(304)
      }
    }

    await next()
  }
}
