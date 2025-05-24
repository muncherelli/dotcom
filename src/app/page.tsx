import Image from "next/image";
import Link from "next/link";
import { prisma } from "@/lib/prisma";

export const dynamic = "force-dynamic"; // Don't cache this page

export default async function Home() {
  // Only fetch notes in development mode
  const isDev = process.env.NODE_ENV === "development";
  
  // Fetch notes with slugs only in dev mode
  const notes = isDev ? await prisma.note.findMany({
    where: {
      Slug: {
        not: null,
      },
      ArchivedAt: null,
      TrashedAt: null,
    },
    orderBy: {
      UpdatedAt: "desc",
    },
    select: {
      ID: true,
      Title: true,
      Slug: true,
      UpdatedAt: true,
    },
    take: 10, // Limit to 10 most recent notes
  }) : [];

  return (
    <main className="min-h-screen p-6 md:p-24">
      <div className="max-w-4xl mx-auto">
        <div className="flex flex-col md:flex-row items-center justify-center gap-4 md:gap-6 mb-12">
          <div className="w-20 h-20 md:w-24 md:h-24 rounded-full overflow-hidden bg-black flex items-center justify-center">
            <Image
              src="https://github.com/muncherelli.png"
              alt="Muncherelli"
              width={96}
              height={96}
              className="object-cover"
              priority
            />
          </div>
          <h1
            className="font-chomsky text-4xl md:text-8xl text-center"
            style={{ letterSpacing: "-0.03em" }}
          >
            muncherelli
          </h1>
        </div>

        {isDev && (
          <div className="mt-8">
            <h2 className="text-2xl font-bold mb-4">Notes</h2>
            {notes.length === 0 ? (
              <p className="text-gray-500">No notes available.</p>
            ) : (
              <ul className="space-y-3">
                {notes.map((note) => (
                  <li key={note.ID} className="border rounded-lg p-3 hover:bg-gray-50 transition-colors">
                    <Link href={`/${note.Slug}`} className="block">
                      <h3 className="text-lg font-medium">{note.Title || 'Untitled'}</h3>
                      <p className="text-sm text-gray-500 mt-1">
                        {new Date(note.UpdatedAt).toLocaleDateString()}
                      </p>
                    </Link>
                  </li>
                ))}
              </ul>
            )}
          </div>
        )}
      </div>
    </main>
  );
}
