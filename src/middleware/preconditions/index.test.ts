import type { PreconditionsValidators } from '.'
import { preconditions } from '.'
import type { Context } from '../../context'
import { Hono } from '../../hono'

const LAST_MODIFIED = 'Sun, 06 Nov 1994 08:49:37 GMT'
const BEFORE = 'Sun, 06 Nov 1994 08:49:36 GMT'
const AFTER = 'Sun, 06 Nov 1994 08:49:38 GMT'

const createApp = (validators: PreconditionsValidators | null) => {
  const describe = vi.fn(() => validators)
  const handler = vi.fn()
  const app = new Hono()
  const middleware = preconditions(describe)
  const respond = (c: Context) => {
    handler()
    c.header('X-Handler', 'yes')
    return c.text('body', 201)
  }
  app.on(['GET', 'POST', 'PUT', 'DELETE', 'QUERY'], '/r', middleware, respond)
  app.get('/plain', respond)
  return { app, describe, handler }
}

const request = (
  app: Hono,
  headers: Record<string, string>,
  method = 'GET',
  path = '/r'
): Promise<Response> => Promise.resolve(app.request(path, { method, headers }))

const expectHandled = async (res: Response, method = 'GET') => {
  expect(res.status).toBe(201)
  expect(res.headers.get('X-Handler')).toBe('yes')
  expect(res.headers.get('ETag')).toBeNull()
  expect(res.headers.get('Last-Modified')).toBeNull()
  expect(await res.text()).toBe(method === 'HEAD' ? '' : 'body')
}

const expectBlocked = async (res: Response, status: 304 | 412) => {
  expect(res.status).toBe(status)
  expect(res.headers.get('X-Handler')).toBeNull()
  expect(await res.text()).toBe('')
}

describe('Preconditions Middleware', () => {
  describe('without usable precondition headers', () => {
    it('does not call describe', async () => {
      const { app, describe, handler } = createApp({ etag: '"a"' })
      await expectHandled(await request(app, {}))
      expect(describe).not.toHaveBeenCalled()
      expect(handler).toHaveBeenCalledTimes(1)
    })

    it('treats blank headers as absent', async () => {
      const { app, describe } = createApp({ etag: '"a"', lastModified: LAST_MODIFIED })
      await expectHandled(
        await request(app, {
          'If-Match': '   ',
          'If-None-Match': '',
          'If-Unmodified-Since': ' ',
          'If-Modified-Since': '',
        })
      )
      expect(describe).not.toHaveBeenCalled()
    })

    it.each([
      'Sun, 31 Feb 2021 00:00:00 GMT',
      '1994-11-06T08:49:37Z',
      'Sunday, 06-Nov-94 08:49:37 GMT',
      'Sun Nov  6 08:49:37 1994',
      'Sun, 06 nov 1994 08:49:37 GMT',
      'Sun, 6 Nov 1994 08:49:37 GMT',
      'Sun, 06 Nov 1994 24:00:00 GMT',
      'Sun, 06 Nov 94 08:49:37 GMT',
      'Sun, 06 Nov 1994 08:49:37 UTC',
    ])('ignores unparseable date %s', async (date) => {
      const { app, describe } = createApp({ lastModified: LAST_MODIFIED })
      await expectHandled(await request(app, { 'If-Modified-Since': date }))
      await expectHandled(await request(app, { 'If-Unmodified-Since': date }, 'PUT'))
      expect(describe).not.toHaveBeenCalled()
    })

    it('ignores If-Modified-Since on unsafe methods', async () => {
      const { app, describe } = createApp({ lastModified: LAST_MODIFIED })
      await expectHandled(await request(app, { 'If-Modified-Since': AFTER }, 'POST'))
      expect(describe).not.toHaveBeenCalled()
    })

    it('never calls describe on routes without the middleware', async () => {
      const { app, describe } = createApp({ etag: '"a"' })
      const res = await request(app, { 'If-None-Match': '"a"' }, 'GET', '/plain')
      expect(res.status).toBe(201)
      expect(describe).not.toHaveBeenCalled()
    })
  })

  describe('If-Match', () => {
    it.each([
      ['"a"', '"a"'],
      ['"a"', '"b", "a"'],
      ['"a"', '"b" ,"a" '],
      ['"a"', 'W/"a", "a"'],
      ['"a,b"', '"x", "a,b"'],
      ['"*"', '"*"'],
      ['""', '""'],
      [' "a" ', '"a"'],
    ])('passes when current %s strongly matches %s', async (etag, header) => {
      const { app, describe } = createApp({ etag })
      await expectHandled(await request(app, { 'If-Match': header }, 'PUT'))
      expect(describe).toHaveBeenCalledTimes(1)
    })

    it.each([
      ['"a"', '"b"'],
      ['"a"', 'W/"a"'],
      ['W/"a"', 'W/"a"'],
      ['W/"a"', '"a"'],
      ['"a"', 'w/"a"'],
      ['"a"', 'a'],
      ['"a"', '"*"'],
      ['"a"', '*, "b"'],
      ['"a"', '"a'],
      ['"a"', '","'],
      ['a', 'a'],
      ['W/ "a"', 'W/ "a"'],
    ])('fails when current %s does not strongly match %s', async (etag, header) => {
      const { app } = createApp({ etag })
      await expectBlocked(await request(app, { 'If-Match': header }, 'PUT'), 412)
    })

    it('does not treat W/ followed by a space as a tag', async () => {
      const { app } = createApp({ etag: '"a"' })
      await expectBlocked(await request(app, { 'If-Match': 'W/ "a"' }, 'PUT'), 412)
    })

    it('returns 412 even for GET, HEAD, and QUERY', async () => {
      const { app } = createApp({ etag: '"a"' })
      for (const method of ['GET', 'HEAD', 'QUERY']) {
        await expectBlocked(await request(app, { 'If-Match': '"b"' }, method), 412)
      }
    })

    it('star passes only when a representation exists', async () => {
      const exists = createApp({})
      await expectHandled(await request(exists.app, { 'If-Match': ' * ' }, 'PUT'))

      const missing = createApp(null)
      const res = await request(missing.app, { 'If-Match': '*' }, 'PUT')
      await expectBlocked(res, 412)
      expect(res.headers.get('ETag')).toBeNull()
    })

    it('fails when there is no current etag', async () => {
      const { app } = createApp({ lastModified: LAST_MODIFIED })
      const res = await request(app, { 'If-Match': '"a"' }, 'PUT')
      await expectBlocked(res, 412)
      expect(res.headers.get('Last-Modified')).toBe(LAST_MODIFIED)
    })

    it('ignores If-Unmodified-Since while present', async () => {
      const { app } = createApp({ etag: '"a"', lastModified: LAST_MODIFIED })
      await expectHandled(
        await request(app, { 'If-Match': '"a"', 'If-Unmodified-Since': BEFORE }, 'PUT')
      )
    })

    it('echoes validators on failure', async () => {
      const { app } = createApp({ etag: ' "a" ', lastModified: new Date(784111777999) })
      const res = await request(app, { 'If-Match': '"b"' }, 'PUT')
      await expectBlocked(res, 412)
      expect(res.headers.get('ETag')).toBe('"a"')
      expect(res.headers.get('Last-Modified')).toBe(LAST_MODIFIED)
    })

    it('omits an invalid etag', async () => {
      const { app } = createApp({ etag: 'a' })
      const res = await request(app, { 'If-Match': '"a"' }, 'PUT')
      await expectBlocked(res, 412)
      expect(res.headers.get('ETag')).toBeNull()
    })
  })

  describe('If-Unmodified-Since', () => {
    it.each([
      [LAST_MODIFIED, 201],
      [AFTER, 201],
      [BEFORE, 412],
    ])('with header %s returns %i', async (header, status) => {
      const { app } = createApp({ lastModified: LAST_MODIFIED })
      const res = await request(app, { 'If-Unmodified-Since': header }, 'DELETE')
      if (status === 201) {
        await expectHandled(res)
      } else {
        await expectBlocked(res, 412)
        expect(res.headers.get('Last-Modified')).toBe(LAST_MODIFIED)
      }
    })

    it('compares whole seconds of a Date', async () => {
      const { app } = createApp({ lastModified: new Date(Date.parse(LAST_MODIFIED) + 999) })
      await expectHandled(await request(app, { 'If-Unmodified-Since': LAST_MODIFIED }, 'PUT'))
    })

    it('parses a wrong weekday', async () => {
      const { app, describe } = createApp({ lastModified: LAST_MODIFIED })
      const res = await request(
        app,
        { 'If-Unmodified-Since': 'Mon, 06 Nov 1994 08:49:36 GMT' },
        'PUT'
      )
      await expectBlocked(res, 412)
      expect(describe).toHaveBeenCalledTimes(1)
    })

    it('applies to GET too', async () => {
      const { app } = createApp({ lastModified: LAST_MODIFIED })
      await expectBlocked(await request(app, { 'If-Unmodified-Since': BEFORE }), 412)
    })

    it('continues without a representation or usable time', async () => {
      for (const validators of [
        null,
        {},
        { lastModified: 'garbage' },
        { lastModified: new Date(NaN) },
        { lastModified: '1994-11-06T08:49:37Z' },
      ]) {
        const { app, describe } = createApp(validators)
        await expectHandled(await request(app, { 'If-Unmodified-Since': BEFORE }, 'PUT'))
        expect(describe).toHaveBeenCalledTimes(1)
      }
    })

    it('trims and canonicalizes string lastModified', async () => {
      const { app } = createApp({ lastModified: '  Fri, 06 Nov 1994 08:49:37 GMT\t' })
      const res = await request(app, { 'If-Unmodified-Since': BEFORE }, 'PUT')
      await expectBlocked(res, 412)
      expect(res.headers.get('Last-Modified')).toBe(LAST_MODIFIED)
    })

    it('does not shift two-digit years into the 1900s', async () => {
      const { app } = createApp({ lastModified: 'Sat, 01 Jan 0050 00:00:00 GMT' })
      const res = await request(
        app,
        { 'If-Unmodified-Since': 'Sat, 01 Jan 1950 00:00:00 GMT' },
        'PUT'
      )
      await expectHandled(res)

      const later = createApp({ lastModified: 'Sat, 01 Jan 1950 00:00:01 GMT' })
      const res2 = await request(
        later.app,
        { 'If-Unmodified-Since': 'Thu, 01 Jan 0050 00:00:00 GMT' },
        'PUT'
      )
      await expectBlocked(res2, 412)
    })

    it('zero-pads years on Last-Modified', async () => {
      const lastModified = new Date(0)
      lastModified.setUTCFullYear(5, 0, 2)
      const { app } = createApp({ lastModified })
      const res = await request(
        app,
        { 'If-Unmodified-Since': 'Mon, 01 Jan 0001 00:00:00 GMT' },
        'PUT'
      )
      await expectBlocked(res, 412)
      expect(res.headers.get('Last-Modified')).toBe('Sun, 02 Jan 0005 00:00:00 GMT')
    })

    it('accepts year 0000 and 9999 but not Dates outside that range', async () => {
      const zero = createApp({ lastModified: 'Mon, 01 Jan 0000 00:00:01 GMT' })
      const res = await request(
        zero.app,
        { 'If-Unmodified-Since': 'Sat, 01 Jan 0000 00:00:00 GMT' },
        'PUT'
      )
      await expectBlocked(res, 412)
      expect(res.headers.get('Last-Modified')).toBe('Sat, 01 Jan 0000 00:00:01 GMT')

      const tooLate = new Date(0)
      tooLate.setUTCFullYear(10000, 0, 1)
      const late = createApp({ lastModified: tooLate })
      await expectHandled(
        await request(late.app, { 'If-Unmodified-Since': 'Fri, 31 Dec 9999 23:59:59 GMT' }, 'PUT')
      )

      const tooEarly = new Date(0)
      tooEarly.setUTCFullYear(-1, 0, 1)
      const early = createApp({ lastModified: tooEarly, etag: '"a"' })
      const res2 = await request(early.app, { 'If-None-Match': '"a"' })
      await expectBlocked(res2, 304)
      expect(res2.headers.get('Last-Modified')).toBeNull()
    })

    it('accepts 29 Feb only in leap years', async () => {
      const { app, describe } = createApp({ lastModified: LAST_MODIFIED })
      await expectHandled(
        await request(app, { 'If-Unmodified-Since': 'Tue, 29 Feb 2000 00:00:00 GMT' }, 'PUT')
      )
      expect(describe).toHaveBeenCalledTimes(1)
      await expectHandled(
        await request(app, { 'If-Unmodified-Since': 'Thu, 29 Feb 1900 00:00:00 GMT' }, 'PUT')
      )
      expect(describe).toHaveBeenCalledTimes(1)
    })
  })

  describe('If-None-Match', () => {
    it.each([
      ['"a"', '"a"'],
      ['"a"', 'W/"a"'],
      ['W/"a"', '"a"'],
      ['W/"a"', '"b", W/"a"'],
    ])('current %s weakly matches %s', async (etag, header) => {
      for (const method of ['GET', 'HEAD', 'QUERY']) {
        const { app, handler } = createApp({ etag })
        const res = await request(app, { 'If-None-Match': header }, method)
        await expectBlocked(res, 304)
        expect(res.headers.get('ETag')).toBe(etag)
        expect(handler).not.toHaveBeenCalled()
      }
      const { app } = createApp({ etag })
      await expectBlocked(await request(app, { 'If-None-Match': header }, 'POST'), 412)
    })

    it.each([
      ['"a"', '"b"'],
      ['"a"', 'w/"a"'],
      ['"a"', 'a'],
      ['"a"', '"*"'],
      ['"a"', '"b", *'],
      ['a', 'a'],
      ['a', '*, a'],
    ])('current %s does not match %s', async (etag, header) => {
      const { app } = createApp({ etag })
      await expectHandled(await request(app, { 'If-None-Match': header }))
      await expectHandled(await request(app, { 'If-None-Match': header }, 'PUT'))
    })

    it('star fails when a representation exists', async () => {
      const { app } = createApp({})
      await expectBlocked(await request(app, { 'If-None-Match': '*' }), 304)
      await expectBlocked(await request(app, { 'If-None-Match': ' * ' }, 'PUT'), 412)
    })

    it('star passes when no representation exists', async () => {
      const { app } = createApp(null)
      await expectHandled(await request(app, { 'If-None-Match': '*' }, 'PUT'))
    })

    it('suppresses If-Modified-Since even on a miss', async () => {
      const { app } = createApp({ etag: '"a"', lastModified: LAST_MODIFIED })
      await expectHandled(
        await request(app, { 'If-None-Match': '"b"', 'If-Modified-Since': AFTER })
      )
    })

    it('keeps HEAD as the request method on a GET route', async () => {
      const app = new Hono()
      let seen: string | undefined
      app.get(
        '/r',
        preconditions((c) => {
          seen = c.req.method
          return { etag: '"a"' }
        }),
        (c) => c.text('body')
      )
      const res = await app.request('/r', { method: 'HEAD', headers: { 'If-None-Match': '"a"' } })
      expect(seen).toBe('HEAD')
      expect(res.status).toBe(304)
      expect(res.headers.get('ETag')).toBe('"a"')
    })

    it('runs after a passing If-Match', async () => {
      const { app } = createApp({ etag: '"a"' })
      await expectBlocked(
        await request(app, { 'If-Match': '"a"', 'If-None-Match': '"a"' }, 'PUT'),
        412
      )
    })
  })

  describe('If-Modified-Since', () => {
    it.each([
      [BEFORE, 201],
      [LAST_MODIFIED, 304],
      [AFTER, 304],
    ])('with header %s returns %i', async (header, status) => {
      for (const method of ['GET', 'HEAD', 'QUERY']) {
        const { app } = createApp({ etag: 'W/"x"', lastModified: LAST_MODIFIED })
        const res = await request(app, { 'If-Modified-Since': header }, method)
        if (status === 201) {
          await expectHandled(res, method)
        } else {
          await expectBlocked(res, 304)
          expect(res.headers.get('ETag')).toBe('W/"x"')
          expect(res.headers.get('Last-Modified')).toBe(LAST_MODIFIED)
        }
      }
    })

    it('continues when the time is missing', async () => {
      for (const validators of [null, { etag: '"a"' }]) {
        const { app, describe } = createApp(validators)
        await expectHandled(await request(app, { 'If-Modified-Since': AFTER }))
        expect(describe).toHaveBeenCalledTimes(1)
      }
    })
  })

  it('calls describe at most once', async () => {
    const { app, describe } = createApp({ etag: '"a"', lastModified: LAST_MODIFIED })
    await expectHandled(
      await request(app, {
        'If-Match': '"a"',
        'If-None-Match': '"b"',
        'If-Unmodified-Since': AFTER,
        'If-Modified-Since': BEFORE,
      })
    )
    expect(describe).toHaveBeenCalledTimes(1)
  })

  it('supports async describe', async () => {
    const app = new Hono()
    app.get(
      '/r',
      preconditions(async () => ({ etag: '"a"' })),
      (c) => c.text('body')
    )
    const res = await app.request('/r', { headers: { 'If-None-Match': '"a"' } })
    expect(res.status).toBe(304)
  })

  it('leaves successful responses unchanged', async () => {
    const app = new Hono()
    app.put(
      '/r',
      preconditions(() => ({ etag: '"a"', lastModified: LAST_MODIFIED })),
      (c) => c.json({ ok: true }, 202, { ETag: '"b"', 'X-Custom': '1' })
    )
    const res = await app.request('/r', { method: 'PUT', headers: { 'If-Match': '"a"' } })
    expect(res.status).toBe(202)
    expect(res.headers.get('ETag')).toBe('"b"')
    expect(res.headers.get('X-Custom')).toBe('1')
    expect(res.headers.get('Last-Modified')).toBeNull()
    expect(await res.json()).toEqual({ ok: true })
  })

  it('handles a throw from describe like a handler error', async () => {
    const app = new Hono()
    const handler = vi.fn()
    app.get(
      '/r',
      preconditions(async () => {
        throw new Error('boom')
      }),
      (c) => {
        handler()
        return c.text('body')
      }
    )
    app.onError((err, c) => c.text(`caught ${err.message}`, 500))
    const res = await app.request('/r', { headers: { 'If-None-Match': '"a"' } })
    expect(res.status).toBe(500)
    expect(await res.text()).toBe('caught boom')
    expect(handler).not.toHaveBeenCalled()
  })

  it('keeps path parameters available', async () => {
    const app = new Hono()
    app.get(
      '/posts/:id',
      preconditions((c) => ({ etag: `"${c.req.param('id')}"` })),
      (c) => c.text(c.req.param('id'))
    )
    let res = await app.request('/posts/42', { headers: { 'If-None-Match': '"42"' } })
    expect(res.status).toBe(304)
    res = await app.request('/posts/7', { headers: { 'If-None-Match': '"42"' } })
    expect(res.status).toBe(200)
    expect(await res.text()).toBe('7')
  })

  it('keeps path parameters available in a mounted sub-application', async () => {
    const sub = new Hono()
    sub.use(
      '/:id',
      preconditions((c) => ({ etag: `"${c.req.param('id')}"` }))
    )
    sub.get('/:id', (c) => c.text(c.req.param('id')))
    const app = new Hono()
    app.route('/posts', sub)

    let res = await app.request('/posts/42', { headers: { 'If-None-Match': '"42"' } })
    expect(res.status).toBe(304)
    expect(res.headers.get('ETag')).toBe('"42"')
    res = await app.request('/posts/7', { headers: { 'If-None-Match': '"42"' } })
    expect(res.status).toBe(200)
    expect(await res.text()).toBe('7')
  })
})

const SUN = 'Sun, 06 Nov 1994 08:49:37 GMT'

const run = async (validators: PreconditionsValidators | null, headers: Record<string, string>, method = 'GET') => {
  const describe = vi.fn(() => validators)
  const handler = vi.fn()
  const app = new Hono()
  app.on([method], '/r', preconditions(describe), (c) => {
    handler()
    return c.text('body')
  })
  const res = await app.request('/r', { method, headers })
  return { res, describe, handler }
}

describe('spec edge cases', () => {
  it('trimmed lone * passes for {} and fails on null', async () => {
    const a = await run({}, { 'If-Match': ' * ' }, 'PUT')
    expect(a.res.status).toBe(200)
    const b = await run(null, { 'If-Match': ' * ' }, 'PUT')
    expect(b.res.status).toBe(412)
    expect(b.handler).not.toHaveBeenCalled()
  })

  it('unquoted v1 exists for * but never matches "v1" and is never sent', async () => {
    const a = await run({ etag: 'v1' }, { 'If-Match': '*' }, 'PUT')
    expect(a.res.status).toBe(200)
    const b = await run({ etag: 'v1' }, { 'If-Match': '"v1"' }, 'PUT')
    expect(b.res.status).toBe(412)
    expect(b.res.headers.get('ETag')).toBeNull()
    const c = await run({ etag: 'v1' }, { 'If-None-Match': '"v1"' })
    expect(c.res.status).toBe(200)
  })

  it('trims a descriptor etag before compare and before send', async () => {
    const a = await run({ etag: ' "v1" ' }, { 'If-Match': '"v1"' }, 'PUT')
    expect(a.res.status).toBe(200)
    const b = await run({ etag: ' W/"v1" ' }, { 'If-None-Match': '"v1"' })
    expect(b.res.status).toBe(304)
    expect(b.res.headers.get('ETag')).toBe('W/"v1"')
  })

  it('"v"1" never matches or gets sent; star is still an empty 304 with Last-Modified', async () => {
    const v = { etag: '"v"1"', lastModified: SUN }
    const a = await run(v, { 'If-None-Match': '"v"1"' })
    expect(a.res.status).toBe(200)
    const b = await run(v, { 'If-None-Match': '*' })
    expect(b.res.status).toBe(304)
    expect(await b.res.text()).toBe('')
    expect(b.res.headers.get('ETag')).toBeNull()
    expect(b.res.headers.get('Last-Modified')).toBe(SUN)
  })

  it('padded ISO and NaN lastModified are ignored, a valid etag still works', async () => {
    for (const lastModified of [' 2024-01-02T03:04:05Z ', new Date(NaN)]) {
      const r = await run({ etag: '"v1"', lastModified }, { 'If-None-Match': '"v1"' })
      expect(r.res.status).toBe(304)
      expect(r.res.headers.get('ETag')).toBe('"v1"')
      expect(r.res.headers.get('Last-Modified')).toBeNull()
    }
  })

  it('year 94 stays 94 and prints four digits', async () => {
    const lm = 'Fri, 01 Jan 0094 00:00:00 GMT'
    const a = await run(
      { etag: '"v1"', lastModified: lm },
      { 'If-Unmodified-Since': 'Sat, 01 Jan 1994 00:00:00 GMT' },
      'PUT'
    )
    expect(a.res.status).toBe(200)
    const b = await run({ etag: '"v1"', lastModified: lm }, { 'If-Match': '"x"' }, 'PUT')
    expect(b.res.status).toBe(412)
    expect(b.res.headers.get('Last-Modified')).toBe(lm)
  })

  it('RFC 850 and asctime on either date header do not call describe', async () => {
    for (const v of ['Sunday, 06-Nov-94 08:49:37 GMT', 'Sun Nov 06 08:49:37 1994']) {
      const a = await run({ lastModified: SUN }, { 'If-Unmodified-Since': v }, 'PUT')
      expect(a.describe).not.toHaveBeenCalled()
      expect(a.res.status).toBe(200)
      const b = await run({ lastModified: SUN }, { 'If-Modified-Since': v })
      expect(b.describe).not.toHaveBeenCalled()
      expect(b.res.status).toBe(200)
    }
  })
})
