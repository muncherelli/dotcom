import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

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

    // delete all data in proper order to respect foreign key constraints
    await prisma.$transaction(async (tx) => {
      // first, clear NoteTags (junction table)
      await tx.$executeRaw`DELETE FROM dbo.NoteTags`;
      
      // then clear Notes table
      await tx.$executeRaw`DELETE FROM dbo.Notes`;
      
      // clear Tags table
      await tx.$executeRaw`DELETE FROM dbo.Tags`;
      
      // finally clear the Bear notes table
      await tx.$executeRaw`DELETE FROM bear.ZSFNOTE`;
      
      // reset identity columns
      await tx.$executeRaw`DBCC CHECKIDENT ('dbo.NoteTags', RESEED, 0)`;
      await tx.$executeRaw`DBCC CHECKIDENT ('dbo.Tags', RESEED, 0)`;
    });

    return NextResponse.json({
      message: "Database tables cleared and identity values reset successfully",
    });
  } catch (error) {
    console.error("Error during resync:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
