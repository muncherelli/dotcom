import Link from "next/link"

export default function SlugNotFound() {
  return (
    <div className="container mx-auto px-4 py-16 text-center">
      <h1 className="text-4xl font-bold mb-6">Page Not Found</h1>
      <p className="text-xl mb-8">
        The page you&apos;re looking for doesn&apos;t exist or may have been moved.
      </p>
      <Link 
        href="/" 
        className="inline-block bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-6 rounded-lg transition-colors"
      >
        Back to Home
      </Link>
    </div>
  )
}