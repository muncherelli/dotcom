import Image from "next/image";

export default function Home() {
  return (
    <main className="flex min-h-screen items-center justify-center p-6 md:p-24">
      <div className="flex flex-col md:flex-row items-center justify-center gap-4 md:gap-6">
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
    </main>
  );
}
