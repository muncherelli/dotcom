import Link from "next/link";
import { prisma } from "@/lib/prisma";

export const dynamic = "force-dynamic"; // Don't cache this page

export default async function NotesIndex() {
  const notes = await prisma.note.findMany({
    where: {
      ArchivedAt: null, // Only show non-archived notes
      TrashedAt: null, // Only show non-trashed notes
      Slug: {
        not: null, // Only show notes with slugs
      },
    },
    orderBy: {
      UpdatedAt: "desc", // Most recently updated first
    },
    select: {
      ID: true,
      Title: true,
      Slug: true,
      UpdatedAt: true,
    },
  });

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="mb-4">
        <Link href="/" className="text-blue-600 hover:text-blue-800">
          ← Home
        </Link>
      </div>
      <h1 className="text-3xl font-bold mb-6">Notes</h1>
      
      {notes.length === 0 ? (
        <p className="text-gray-500">No notes available.</p>
      ) : (
        <ul className="space-y-4">
          {notes.map((note) => (
            <li key={note.ID} className="border rounded-lg p-4 hover:shadow-md transition-shadow">
              <Link href={`/${note.Slug}`} className="block">
                <h2 className="text-xl font-semibold">{note.Title || "Untitled"}</h2>
                <p className="text-sm text-gray-500 mt-2">
                  Last updated: {note.UpdatedAt.toLocaleString()}
                </p>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}