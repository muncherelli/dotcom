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

    // Truncate both tables
    await prisma.$executeRaw`TRUNCATE TABLE dbo.Notes`;
    await prisma.$executeRaw`TRUNCATE TABLE bear.ZSFNOTE`;

    return NextResponse.json({
      message: "Database tables truncated successfully",
    });
  } catch (error) {
    console.error("Error during resync:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
