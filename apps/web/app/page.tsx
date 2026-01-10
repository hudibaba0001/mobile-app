import Link from 'next/link'

export default function HomePage() {
  return (
    <div className="container">
      <div className="card message-page">
        <h1 className="title">Time Tracker</h1>
        <p>
          Track your work hours and travel time with ease.
        </p>
        <Link
          href="/signup"
          className="button"
          style={{ display: 'block', textAlign: 'center', textDecoration: 'none' }}
        >
          Create Account
        </Link>
        <p style={{ marginTop: '16px', fontSize: '14px', color: '#666' }}>
          Already have an account? Open the mobile app to log in.
        </p>
      </div>
    </div>
  )
}
