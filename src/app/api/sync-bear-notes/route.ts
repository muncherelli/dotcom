import { NextResponse } from "next/server";
import { prisma } from "@/libraries/prisma";
import matter from "gray-matter";
import { plistDateToJSDate } from "@/lib/date-utils";

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

    const notes = await request.json();

    for (const note of notes) {
      // First, upsert into bear.ZSFNOTE
      await prisma.bearNote.upsert({
        where: {
          Z_PK: note.Z_PK,
        },
        update: {
          Z_ENT: note.Z_ENT,
          Z_OPT: note.Z_OPT,
          ZARCHIVED: note.ZARCHIVED,
          ZENCRYPTED: note.ZENCRYPTED,
          ZHASFILES: note.ZHASFILES,
          ZHASIMAGES: note.ZHASIMAGES,
          ZHASSOURCECODE: note.ZHASSOURCECODE,
          ZLOCKED: note.ZLOCKED,
          ZORDER: note.ZORDER,
          ZPERMANENTLYDELETED: note.ZPERMANENTLYDELETED,
          ZPINNED: note.ZPINNED,
          ZSHOWNINTODAYWIDGET: note.ZSHOWNINTODAYWIDGET,
          ZSKIPSYNC: note.ZSKIPSYNC,
          ZTODOCOMPLETED: note.ZTODOCOMPLETED,
          ZTODOINCOMPLETED: note.ZTODOINCOMPLETED,
          ZTRASHED: note.ZTRASHED,
          ZVERSION: note.ZVERSION,
          ZPASSWORD: note.ZPASSWORD,
          ZSERVERDATA: note.ZSERVERDATA,
          ZARCHIVEDDATE: note.ZARCHIVEDDATE,
          ZCONFLICTUNIQUEIDENTIFIERDATE: note.ZCONFLICTUNIQUEIDENTIFIERDATE,
          ZCREATIONDATE: note.ZCREATIONDATE,
          ZLOCKEDDATE: note.ZLOCKEDDATE,
          ZMODIFICATIONDATE: note.ZMODIFICATIONDATE,
          ZORDERDATE: note.ZORDERDATE,
          ZPINNEDDATE: note.ZPINNEDDATE,
          ZTRASHEDDATE: note.ZTRASHEDDATE,
          ZCONFLICTUNIQUEIDENTIFIER: note.ZCONFLICTUNIQUEIDENTIFIER,
          ZENCRYPTIONUNIQUEIDENTIFIER: note.ZENCRYPTIONUNIQUEIDENTIFIER,
          ZLASTEDITINGDEVICE: note.ZLASTEDITINGDEVICE,
          ZSUBTITLE: note.ZSUBTITLE,
          ZTEXT: note.ZTEXT,
          ZTITLE: note.ZTITLE,
          ZUNIQUEIDENTIFIER: note.ZUNIQUEIDENTIFIER,
        },
        create: {
          Z_PK: note.Z_PK,
          Z_ENT: note.Z_ENT,
          Z_OPT: note.Z_OPT,
          ZARCHIVED: note.ZARCHIVED,
          ZENCRYPTED: note.ZENCRYPTED,
          ZHASFILES: note.ZHASFILES,
          ZHASIMAGES: note.ZHASIMAGES,
          ZHASSOURCECODE: note.ZHASSOURCECODE,
          ZLOCKED: note.ZLOCKED,
          ZORDER: note.ZORDER,
          ZPERMANENTLYDELETED: note.ZPERMANENTLYDELETED,
          ZPINNED: note.ZPINNED,
          ZSHOWNINTODAYWIDGET: note.ZSHOWNINTODAYWIDGET,
          ZSKIPSYNC: note.ZSKIPSYNC,
          ZTODOCOMPLETED: note.ZTODOCOMPLETED,
          ZTODOINCOMPLETED: note.ZTODOINCOMPLETED,
          ZTRASHED: note.ZTRASHED,
          ZVERSION: note.ZVERSION,
          ZPASSWORD: note.ZPASSWORD,
          ZSERVERDATA: note.ZSERVERDATA,
          ZARCHIVEDDATE: note.ZARCHIVEDDATE,
          ZCONFLICTUNIQUEIDENTIFIERDATE: note.ZCONFLICTUNIQUEIDENTIFIERDATE,
          ZCREATIONDATE: note.ZCREATIONDATE,
          ZLOCKEDDATE: note.ZLOCKEDDATE,
          ZMODIFICATIONDATE: note.ZMODIFICATIONDATE,
          ZORDERDATE: note.ZORDERDATE,
          ZPINNEDDATE: note.ZPINNEDDATE,
          ZTRASHEDDATE: note.ZTRASHEDDATE,
          ZCONFLICTUNIQUEIDENTIFIER: note.ZCONFLICTUNIQUEIDENTIFIER,
          ZENCRYPTIONUNIQUEIDENTIFIER: note.ZENCRYPTIONUNIQUEIDENTIFIER,
          ZLASTEDITINGDEVICE: note.ZLASTEDITINGDEVICE,
          ZSUBTITLE: note.ZSUBTITLE,
          ZTEXT: note.ZTEXT,
          ZTITLE: note.ZTITLE,
          ZUNIQUEIDENTIFIER: note.ZUNIQUEIDENTIFIER,
        },
      });

      // Then, extract title from frontmatter or ZTITLE and upsert into dbo.Notes
      const { data: frontMatter } = matter(note.ZTEXT || "");
      const title = frontMatter.title || note.ZTITLE;

      // Convert PLIST dates to JavaScript Date objects
      const createdAt = plistDateToJSDate(note.ZCREATIONDATE);
      const updatedAt = plistDateToJSDate(note.ZMODIFICATIONDATE);
      const archivedAt = plistDateToJSDate(note.ZARCHIVEDDATE);
      const lockedAt = plistDateToJSDate(note.ZLOCKEDDATE);
      const pinnedAt = plistDateToJSDate(note.ZPINNEDDATE);
      const trashedAt = plistDateToJSDate(note.ZTRASHEDDATE);

      await prisma.note.upsert({
        where: {
          ID: note.Z_PK,
        },
        update: {
          Title: title,
          UpdatedAt: updatedAt || new Date(),
          ArchivedAt: archivedAt,
          LockedAt: lockedAt,
          PinnedAt: pinnedAt,
          TrashedAt: trashedAt,
        },
        create: {
          ID: note.Z_PK,
          Title: title,
          CreatedAt: createdAt || new Date(),
          UpdatedAt: updatedAt || new Date(),
          ArchivedAt: archivedAt,
          LockedAt: lockedAt,
          PinnedAt: pinnedAt,
          TrashedAt: trashedAt,
        },
      });
    }

    return NextResponse.json({ message: "Notes synced successfully" });
  } catch (error) {
    console.error("Error syncing notes:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
