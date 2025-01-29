import { z } from "zod";
import { withValidation } from "@/lib/api-handler";
import prisma from "@/lib/db";

const BodySchema = z.array(
  z.object({
    ID: z.number().int(),
    ZMODIFICATIONDATE: z.number(),
  }),
);

export const POST = withValidation(BodySchema, async (data) => {
  console.table(data);
  const articles = await prisma.article.findMany({
    where: {
      ID: {
        in: data.map((d) => d.ID),
      },
    },
    select: {
      ID: true,
    },
  });
  return new Response(JSON.stringify(articles));
});
