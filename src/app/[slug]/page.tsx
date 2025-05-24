import { notFound } from 'next/navigation'
import { prisma } from '@/lib/prisma'
import Link from 'next/link'

export const dynamic = 'force-dynamic' // Don't cache this page

interface SlugPageProps {
  params: {
    slug: string
  }
}

export default async function SlugPage({ params }: SlugPageProps) {
  // In Next.js 14, params should be awaited
  const { slug } = await Promise.resolve(params)

  // Check if this is a note
  const note = await prisma.note.findFirst({
    where: {
      Slug: slug,
      ArchivedAt: null, // Only show non-archived notes
      TrashedAt: null, // Only show non-trashed notes
    },
  })

  if (!note) {
    notFound()
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="mb-4">
        <Link href="/" className="text-blue-600 hover:text-blue-800">
          ← Home
        </Link>
      </div>
      <h1 className="text-3xl font-bold mb-6">{note.Title}</h1>
      <div className="prose prose-lg max-w-none">
        {note.HTML ? (
          <div dangerouslySetInnerHTML={{ __html: note.HTML }} />
        ) : (
          <p>No content available.</p>
        )}
      </div>
      <div className="mt-6 text-sm text-gray-500">
        <p>Last updated: {note.UpdatedAt.toLocaleString()}</p>
      </div>
    </div>
  )
}