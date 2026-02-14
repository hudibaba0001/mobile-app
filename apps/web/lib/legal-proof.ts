interface WordPressPage {
  modified_gmt?: string
  modified?: string
  date_gmt?: string
  date?: string
  content?: {
    rendered?: string
  }
}

export interface LegalSnapshot {
  url: string
  version: string
  modifiedAt: string | null
  content: string
}

export const TERMS_URL = 'https://www.kviktime.se/terms-and-conditions/'
export const PRIVACY_URL = 'https://www.kviktime.se/privacy-policy/'

const TERMS_SLUG = 'terms-and-conditions'
const PRIVACY_SLUG = 'privacy-policy'

function extractTextFromHtml(html: string): string {
  return html
    .replace(/<script[\s\S]*?<\/script>/gi, '')
    .replace(/<style[\s\S]*?<\/style>/gi, '')
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
}

function normalizeWordPressUtc(rawValue: string | undefined): string | null {
  if (!rawValue || !rawValue.trim()) return null
  const value = rawValue.trim()
  const isoCandidate = value.endsWith('Z') ? value : `${value}Z`
  const parsed = new Date(isoCandidate)
  if (Number.isNaN(parsed.getTime())) return null
  return parsed.toISOString()
}

async function fetchWordPressSnapshot({
  slug,
  url,
  fallbackVersion,
}: {
  slug: string
  url: string
  fallbackVersion: string
}): Promise<LegalSnapshot> {
  try {
    const apiUrl = new URL('/wp-json/wp/v2/pages', url)
    apiUrl.searchParams.set('slug', slug)
    apiUrl.searchParams.set('_fields', 'modified_gmt,modified,date_gmt,date,content')

    const response = await fetch(apiUrl.toString(), {
      method: 'GET',
      cache: 'no-store',
    })

    if (response.ok) {
      const pages = (await response.json()) as WordPressPage[]
      const page = pages[0]
      if (page?.content?.rendered) {
        const modifiedAt = normalizeWordPressUtc(
          page.modified_gmt ?? page.modified ?? page.date_gmt ?? page.date,
        )
        return {
          url,
          version: modifiedAt ? `wp-${modifiedAt}` : fallbackVersion,
          modifiedAt,
          content: extractTextFromHtml(page.content.rendered),
        }
      }
    }
  } catch {
    // Fall back to direct page fetch below.
  }

  try {
    const response = await fetch(url, {
      method: 'GET',
      cache: 'no-store',
    })
    if (response.ok) {
      const html = await response.text()
      return {
        url,
        version: fallbackVersion,
        modifiedAt: null,
        content: extractTextFromHtml(html),
      }
    }
  } catch {
    // Fall through to explicit fallback.
  }

  return {
    url,
    version: fallbackVersion,
    modifiedAt: null,
    content: '[Unable to fetch legal document snapshot]',
  }
}

export async function fetchCurrentLegalSnapshots({
  termsFallbackVersion,
  privacyFallbackVersion,
}: {
  termsFallbackVersion: string
  privacyFallbackVersion: string
}): Promise<{ terms: LegalSnapshot; privacy: LegalSnapshot }> {
  const [terms, privacy] = await Promise.all([
    fetchWordPressSnapshot({
      slug: TERMS_SLUG,
      url: TERMS_URL,
      fallbackVersion: termsFallbackVersion,
    }),
    fetchWordPressSnapshot({
      slug: PRIVACY_SLUG,
      url: PRIVACY_URL,
      fallbackVersion: privacyFallbackVersion,
    }),
  ])

  return { terms, privacy }
}
