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
    const bearNotes = await request.json();

    // process each note
    for (const bearNote of bearNotes) {
      const existingNote = await prisma.bearNote.findUnique({
        where: { Z_PK: bearNote.Z_PK },
      });

      if (!existingNote) {
        // insert new note
        await prisma.bearNote.create({
          data: { ...bearNote },
        });
      } else if (
        existingNote.ZMODIFICATIONDATE !== bearNote.ZMODIFICATIONDATE
      ) {
        // update existing note if modified date is different
        await prisma.bearNote.update({
          where: { Z_PK: bearNote.Z_PK },
          data: { ...bearNote },
        });
      }
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error("Error syncing Bear notes:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
