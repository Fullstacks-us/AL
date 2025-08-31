# AL — Contributor Landing & Application: Deployment Plan + Starter Code

Sigh. You started an empty repo and expect it to blossom into a polished, data‑capturing, nicely branded landing site. Fine. Here’s a complete, cut‑pasteable plan with starter code so that even future‑you can’t sabotage it.

---

## Goals
- Public landing page for **AL** project
- Intake form for **contributor applications**
- Store submissions in **MongoDB**
- Optional email notifications
- Deploy on **Vercel** with sane CI, issue templates, and docs

---

## Tech Stack
- **Next.js 14** (App Router, TypeScript)
- **Tailwind CSS** + **shadcn/ui** (clean UI without crying)
- **MongoDB Atlas** (application storage)
- **Zod** + **React Hook Form** (validation)
- **Rate limiting** via simple in‑memory limiter on serverless edge or Upstash (optional)
- **Resend** for email notifications (optional)

---

## Repo Structure
```
AL/
├─ app/
│  ├─ layout.tsx
│  ├─ page.tsx                 # Landing page
│  ├─ apply/
│  │  ├─ page.tsx              # Application form
│  │  └─ success/page.tsx      # Thank‑you page
│  └─ api/
│     └─ apply/route.ts        # POST handler for submissions
├─ components/
│  ├─ ui/                      # shadcn components
│  └─ forms/
│     └─ ApplicationForm.tsx
├─ lib/
│  ├─ db.ts                    # Mongo connection helper
│  └─ validators.ts            # Zod schemas
├─ prisma/                     # optional if you want Prisma later (not required)
├─ public/
│  └─ logo.svg
├─ .github/
│  ├─ workflows/deploy.yml     # CI: typecheck + lint + build
│  └─ ISSUE_TEMPLATE/
│     ├─ bug_report.yml
│     └─ feature_request.yml
├─ .env.example
├─ package.json
├─ tailwind.config.ts
├─ postcss.config.mjs
├─ tsconfig.json
├─ next.config.mjs
├─ README.md
└─ LICENSE
```

---

## Setup (copy, paste, try not to blink)
```bash
# 1) Create Next app
pnpm create next-app@latest AL --ts --eslint --tailwind --app --src-dir=false --import-alias "@/*"
cd AL

# 2) Install deps
pnpm add zod react-hook-form @hookform/resolvers mongoose
pnpm add -D @types/node prettier

# 3) shadcn/ui
pnpm dlx shadcn-ui@latest init -y
pnpm dlx shadcn-ui@latest add button input textarea label form card toast

# 4) Add files from this doc into the repo (app, lib, components, .github, etc.)

# 5) Git bootstrap
git init && git add . && git commit -m "feat: bootstrap AL landing + apply"

# 6) Vercel
# Create new project targeting this repo and add env vars below.
```

---

## Environment Variables (.env)
```
# Required
MONGODB_URI=mongodb+srv://<user>:<pass>@<cluster>/<db>?retryWrites=true&w=majority
NEXT_PUBLIC_SITE_NAME=AL
NEXT_PUBLIC_BRAND_TAGLINE=Apply to build with us

# Optional (email notifications)
RESEND_API_KEY=...         # If using Resend
NOTIFY_TO=email@example.com
```

Commit a safe sample as `.env.example` (not secrets, obviously).

---

## lib/db.ts
```ts
// lib/db.ts
import mongoose from "mongoose";

const MONGODB_URI = process.env.MONGODB_URI as string;
if (!MONGODB_URI) throw new Error("MONGODB_URI missing");

let cached = (global as any).mongoose as { conn: typeof mongoose | null; promise: Promise<typeof mongoose> | null };
if (!cached) cached = (global as any).mongoose = { conn: null, promise: null };

export async function dbConnect() {
  if (cached.conn) return cached.conn;
  if (!cached.promise) {
    cached.promise = mongoose.connect(MONGODB_URI, { bufferCommands: false });
  }
  cached.conn = await cached.promise;
  return cached.conn;
}

const ApplicationSchema = new mongoose.Schema(
  {
    fullName: String,
    email: String,
    role: String,
    portfolioUrl: String,
    github: String,
    linkedin: String,
    location: String,
    experienceYears: Number,
    skills: [String],
    motivation: String,
    availability: String,
    heardFrom: String,
    consent: Boolean,
  },
  { timestamps: true }
);

export const Application = mongoose.models.Application || mongoose.model("Application", ApplicationSchema);
```

---

## lib/validators.ts
```ts
import { z } from "zod";

export const applicationSchema = z.object({
  fullName: z.string().min(2),
  email: z.string().email(),
  role: z.string().min(2),
  portfolioUrl: z.string().url().optional().or(z.literal("")),
  github: z.string().url().optional().or(z.literal("")),
  linkedin: z.string().url().optional().or(z.literal("")),
  location: z.string().min(2),
  experienceYears: z.coerce.number().min(0).max(50),
  skills: z.string().min(2),              // comma‑separated, split server‑side
  motivation: z.string().min(10).max(1500),
  availability: z.string().min(2),
  heardFrom: z.string().optional().or(z.literal("")),
  consent: z.boolean().refine(Boolean, "Consent is required"),
});

export type ApplicationInput = z.infer<typeof applicationSchema>;
```

---

## app/layout.tsx
```tsx
export const metadata = { title: "AL — Contributors", description: "Apply to build with us" };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-neutral-950 text-neutral-100 antialiased">
        <div className="mx-auto max-w-5xl px-6 py-10">
          <header className="flex items-center justify-between py-4">
            <div className="text-xl font-bold tracking-tight">{process.env.NEXT_PUBLIC_SITE_NAME || "AL"}</div>
            <nav className="text-sm opacity-80">
              <a className="hover:opacity-100" href="/apply">Apply</a>
            </nav>
          </header>
          <main>{children}</main>
          <footer className="py-12 text-sm opacity-70">© {new Date().getFullYear()} AL.</footer>
        </div>
      </body>
    </html>
  );
}
```

---

## app/page.tsx (Landing)
```tsx
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";

export default function Page() {
  return (
    <section className="grid gap-8">
      <div className="grid gap-4">
        <h1 className="text-4xl font-semibold">Build with {process.env.NEXT_PUBLIC_SITE_NAME || "AL"}</h1>
        <p className="max-w-2xl text-neutral-300">{process.env.NEXT_PUBLIC_BRAND_TAGLINE || "A contributor program for builders, operators, and tinkerers."}</p>
        <div className="flex gap-4">
          <Button asChild><a href="/apply">Apply now</a></Button>
          <a href="#about" className="text-sm underline opacity-80 hover:opacity-100">Learn more</a>
        </div>
      </div>

      <Card id="about" className="p-6 bg-neutral-900 border-neutral-800">
        <h2 className="text-2xl mb-2">What we’re building</h2>
        <ul className="list-disc ml-6 space-y-1 text-neutral-300">
          <li>Automation agents (Fetcher), milestone engine, governance & metrics.</li>
          <li>Video factory, referral engine, and contributor dashboards.</li>
          <li>Transparent KPIs tied to payouts and equity programs.</li>
        </ul>
      </Card>
    </section>
  );
}
```

---

## components/forms/ApplicationForm.tsx
```tsx
"use client";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { applicationSchema, type ApplicationInput } from "@/lib/validators";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { useState } from "react";

export default function ApplicationForm() {
  const [submitting, setSubmitting] = useState(false);
  const { register, handleSubmit, formState: { errors } } = useForm<ApplicationInput>({
    resolver: zodResolver(applicationSchema),
  });

  const onSubmit = async (data: ApplicationInput) => {
    setSubmitting(true);
    const res = await fetch("/api/apply", { method: "POST", body: JSON.stringify(data) });
    setSubmitting(false);
    if (res.ok) window.location.href = "/apply/success";
    else alert("Submission failed. Try again without breaking the internet.");
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="grid gap-4">
      <div className="grid gap-1">
        <label>Full name</label>
        <Input {...register("fullName")} />
        {errors.fullName && <p className="text-red-400 text-sm">{errors.fullName.message}</p>}
      </div>
      <div className="grid gap-1">
        <label>Email</label>
        <Input type="email" {...register("email")} />
        {errors.email && <p className="text-red-400 text-sm">{errors.email.message}</p>}
      </div>
      <div className="grid gap-1">
        <label>Desired role</label>
        <Input {...register("role")} />
      </div>
      <div className="grid gap-1">
        <label>Portfolio URL</label>
        <Input placeholder="https://" {...register("portfolioUrl")} />
      </div>
      <div className="grid gap-1">
        <label>GitHub</label>
        <Input placeholder="https://github.com/username" {...register("github")} />
      </div>
      <div className="grid gap-1">
        <label>LinkedIn</label>
        <Input placeholder="https://linkedin.com/in/..." {...register("linkedin")} />
      </div>
      <div className="grid gap-1">
        <label>Location</label>
        <Input {...register("location")} />
      </div>
      <div className="grid gap-1">
        <label>Years of experience</label>
        <Input type="number" min={0} max={50} {...register("experienceYears")} />
      </div>
      <div className="grid gap-1">
        <label>Key skills (comma‑separated)</label>
        <Input placeholder="TypeScript, DevOps, UI/UX" {...register("skills")} />
      </div>
      <div className="grid gap-1">
        <label>Motivation</label>
        <Textarea rows={6} {...register("motivation")} />
      </div>
      <div className="grid gap-1">
        <label>Availability</label>
        <Input placeholder="10 hrs/week" {...register("availability")} />
      </div>
      <div className="grid gap-1">
        <label>How did you hear about us?</label>
        <Input {...register("heardFrom")} />
      </div>
      <div className="flex items-center gap-2">
        <input type="checkbox" id="consent" {...register("consent")} />
        <label htmlFor="consent" className="text-sm opacity-80">I consent to storage and review of my application.</label>
      </div>
      <Button type="submit" disabled={submitting}>{submitting ? "Submitting…" : "Submit application"}</Button>
    </form>
  );
}
```

---

## app/apply/page.tsx
```tsx
import { Card } from "@/components/ui/card";
import ApplicationForm from "@/components/forms/ApplicationForm";

export default function ApplyPage() {
  return (
    <div className="grid gap-6">
      <h1 className="text-3xl font-semibold">Contributor application</h1>
      <Card className="p-6 bg-neutral-900 border-neutral-800">
        <ApplicationForm />
      </Card>
    </div>
  );
}
```

---

## app/apply/success/page.tsx
```tsx
export default function SuccessPage() {
  return (
    <div className="grid gap-3">
      <h1 className="text-3xl font-semibold">Thanks — application received</h1>
      <p className="text-neutral-300">We’ll review your info and get back to you if you aren’t obviously a bot. If you are a bot, respect for trying.</p>
      <a className="underline" href="/">Back to home</a>
    </div>
  );
}
```

---

## app/api/apply/route.ts
```ts
import { NextRequest, NextResponse } from "next/server";
import { applicationSchema } from "@/lib/validators";
import { dbConnect, Application } from "@/lib/db";

export async function POST(req: NextRequest) {
  try {
    const json = await req.json();
    const parsed = applicationSchema.parse(json);

    await dbConnect();
    const doc = await Application.create({
      ...parsed,
      skills: parsed.skills.split(",").map(s => s.trim()).filter(Boolean),
    });

    // Optional: email notification via Resend
    if (process.env.RESEND_API_KEY && process.env.NOTIFY_TO) {
      // import { Resend } from "resend"; const resend = new Resend(process.env.RESEND_API_KEY);
      // await resend.emails.send({ to: process.env.NOTIFY_TO!, from: "noreply@al.dev", subject: "New application", text: JSON.stringify(doc, null, 2) });
    }

    return NextResponse.json({ ok: true });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    return NextResponse.json({ ok: false, error: msg }, { status: 400 });
  }
}
```

---

## CI: .github/workflows/deploy.yml
```yml
name: ci
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v3
        with: { version: 9 }
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm run build
```

---

## Issue Templates (.github/ISSUE_TEMPLATE)
```yml
# bug_report.yml
name: Bug Report
description: Something is broken. Again.
labels: [bug]
body:
  - type: textarea
    id: what
    attributes:
      label: What happened?
      description: What did you expect vs reality?
    validations:
      required: true
  - type: input
    id: url
    attributes:
      label: URL
      placeholder: https://al.site/path
```
```yml
# feature_request.yml
name: Feature Request
description: Wish list item, preferably realistic.
labels: [enhancement]
body:
  - type: textarea
    id: value
    attributes:
      label: Value
      description: Who benefits and how do we measure it?
    validations:
      required: true
```

---

## README.md (starter)
```md
# AL — Contributor Landing

Public site for contributors to learn about AL and apply to join.

## Stack
Next.js 14, Tailwind, shadcn/ui, MongoDB. Optional: Resend for email alerts.

## Getting Started
1. `pnpm i`
2. Copy `.env.example` to `.env` and fill values
3. `pnpm dev`

## Deploy
- Recommend Vercel. Set env vars in project settings. Connect `main` branch.

## Roadmap
- Admin review UI, CSV export, webhook to internal tools, rate limiting, captcha.
```

---

## Vercel Notes
- Protect `/api/apply` from spam with **bot protection** (Turnstile/hCaptcha) when you notice pain.
- Set `MONGODB_URI` and other envs per environment.
- Turn on preview deployments so you can review PRs without breaking prod.

---

## Milestones
1) **MVP**: Landing, Apply form, DB write, Success page, CI green, deployed.
2) **Ops**: Email notifications, admin review list, CSV export.
3) **Growth**: Referral codes, contributor dashboard, video factory teaser.

---

## Admin Review UI (phase 2 sketch)
- `/admin` protected route, simple table of applications
- Filters: role, skills, status; actions: shortlist, reject, export
- Auth: magic link or basic password with middleware until you wire proper SSO.

---

## License & Compliance
- Add a permissive LICENSE (MIT) unless you enjoy paperwork.
- Link to `governance.md` and `human_feedbackloop_requirements.md` when they exist.

---

## What you still owe this repo
- Branding (logo, colors, copy polish)
- Captcha + rate limiting
- Analytics (PostHog or equivalent)
- Admin UI

When you’re ready, push this to `Fullstacks-us/AL`, wire Vercel, and stop pretending the repo is empty.

