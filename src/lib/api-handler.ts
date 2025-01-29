import { ZodSchema, ZodError } from "zod";

type Handler = (data: T, req: Request) => Promise<Response>;

export function withValidation(schema: ZodSchema, handler: Handler) {
  return async function (req: Request): Promise<Response> {
    try {
      const body = await req.json();
      const data = schema.parse(body);

      return await handler(data, req);
    } catch (err: unknown) {
      let message = "unknown error";

      if (err instanceof ZodError) {
        message = JSON.stringify(err.errors);
      } else if (err instanceof Error) {
        message = err.message;
      }

      return new Response(JSON.stringify({ error: message }), { status: 400 });
    }
  };
}
