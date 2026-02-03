import { NextRequest, NextResponse } from 'next/server';

interface RateLimitStore {
  count: number;
  resetTime: number;
}

// In-memory store for rate limiting
// In production, use Redis or similar
const rateLimitStore = new Map<string, RateLimitStore>();

export interface RateLimitConfig {
  windowMs: number; // Time window in milliseconds
  maxRequests: number; // Max requests per window
}

// Default: 100 requests per 15 minutes
const defaultConfig: RateLimitConfig = {
  windowMs: 15 * 60 * 1000,
  maxRequests: 100,
};

export function rateLimit(config: RateLimitConfig = defaultConfig) {
  return async (request: NextRequest): Promise<NextResponse | null> => {
    // Get client identifier (IP address or user ID from token)
    const identifier = getClientIdentifier(request);
    const now = Date.now();

    // Get or create rate limit entry
    let entry = rateLimitStore.get(identifier);

    // Reset if window has passed
    if (!entry || now > entry.resetTime) {
      entry = {
        count: 0,
        resetTime: now + config.windowMs,
      };
      rateLimitStore.set(identifier, entry);
    }

    // Increment count
    entry.count++;

    // Check if limit exceeded
    if (entry.count > config.maxRequests) {
      const retryAfter = Math.ceil((entry.resetTime - now) / 1000);

      return NextResponse.json(
        {
          error: 'Too many requests',
          message: `Rate limit exceeded. Try again in ${retryAfter} seconds.`,
        },
        {
          status: 429,
          headers: {
            'Retry-After': retryAfter.toString(),
            'X-RateLimit-Limit': config.maxRequests.toString(),
            'X-RateLimit-Remaining': '0',
            'X-RateLimit-Reset': new Date(entry.resetTime).toISOString(),
          },
        }
      );
    }

    // Clean up old entries periodically (every 1000 requests)
    if (rateLimitStore.size > 10000) {
      cleanupOldEntries();
    }

    return null; // Allow request to proceed
  };
}

function getClientIdentifier(request: NextRequest): string {
  // Try to get IP address
  const forwarded = request.headers.get('x-forwarded-for');
  const realIp = request.headers.get('x-real-ip');
  const ip = forwarded?.split(',')[0] || realIp || 'unknown';

  // Try to get user ID from auth header
  const authHeader = request.headers.get('authorization');
  if (authHeader?.startsWith('Bearer ')) {
    try {
      const token = authHeader.substring(7);
      const payload = JSON.parse(atob(token.split('.')[1]));
      return `user:${payload.sub || payload.id}`;
    } catch (e) {
      // Fall back to IP
    }
  }

  return `ip:${ip}`;
}

function cleanupOldEntries() {
  const now = Date.now();
  for (const [key, entry] of rateLimitStore.entries()) {
    if (now > entry.resetTime) {
      rateLimitStore.delete(key);
    }
  }
}

// Wrapper for admin endpoints with stricter limits
export const adminRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  maxRequests: 50, // 50 requests per 15 minutes
});
