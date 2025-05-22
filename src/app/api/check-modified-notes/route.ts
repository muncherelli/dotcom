import { NextResponse } from "next/server";
import { prisma } from "@/libraries/prisma";

export async function POST(request: Request) {
  try {
    // verify API key
    const authHeader = request.headers.get("authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const apiKey = authHeader.split(" ")[1];
    if (apiKey !== process.env.API_KEY) {
      return NextResponse.json({ error: "Invalid API key" }, { status: 401 });
    }

    // get the notes data from the request
    const { ZMODIFICATIONDATES: bearNotes } = await request.json();

    // get all existing notes from the database
    const existingNotes = await prisma.bearNote.findMany({
      where: {
        Z_PK: {
          in: Object.keys(bearNotes).map(Number),
        },
      },
      select: {
        Z_PK: true,
        ZMODIFICATIONDATE: true,
      },
    });

    // create a map of existing notes for quick lookup
    const existingNotesMap = new Map(
      existingNotes.map(
        (note: { Z_PK: number; ZMODIFICATIONDATE: number | null }) => [
          note.Z_PK,
          note.ZMODIFICATIONDATE,
        ]
      )
    );

    // find notes that need updating (either new or modified)
    const notesToUpdate = Object.entries(bearNotes)
      .filter(([pk, modDate]) => {
        const existingDate = existingNotesMap.get(Number(pk));
        return !existingDate || existingDate !== modDate;
      })
      .map(([pk]) => Number(pk));

    // return just the PKs of notes that need updating
    return NextResponse.json(notesToUpdate);
  } catch (error) {
    console.error("Error checking modified notes:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
