# Pattern: NextAuth.js Authentication (NextAuth + Prisma + bcrypt)

## Problem It Solves
Secure user authentication for Next.js applications with both credentials (email/password) and OAuth (Google) login, role-based access control, and JWT session management.

## Source Project
**Credit** (Grade: B+) -- `/mnt/e/projects/credit/lib/auth.ts`

## When to Use
- Any Next.js project that needs user login/registration
- Projects with role-based access (USER, ADMIN, INSTRUCTOR, etc.)
- Projects using Prisma as the ORM

## Dependencies
```bash
npm install next-auth @auth/prisma-adapter @prisma/client bcryptjs
npm install -D @types/bcryptjs
```

## Code Template

### `lib/auth.ts` -- Core auth configuration
```typescript
import { NextAuthOptions } from 'next-auth';
import { PrismaAdapter } from '@auth/prisma-adapter';
import CredentialsProvider from 'next-auth/providers/credentials';
import GoogleProvider from 'next-auth/providers/google';
import bcrypt from 'bcryptjs';
import prisma from '@/lib/prisma';
import type { Adapter } from 'next-auth/adapters';
import type { Session } from 'next-auth';

interface UserWithRole {
  id: string;
  email: string;
  name: string | null;
  role: string;
}

interface ExtendedSession extends Session {
  user: {
    id: string;
    email: string;
    name?: string | null;
    role: string;
  };
}

export const authOptions: NextAuthOptions = {
  adapter: PrismaAdapter(prisma) as Adapter,
  providers: [
    CredentialsProvider({
      name: 'credentials',
      credentials: {
        email: { label: 'Email', type: 'email' },
        password: { label: 'Password', type: 'password' },
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) {
          throw new Error('Email and password are required');
        }

        const user = await prisma.user.findUnique({
          where: { email: credentials.email },
        });

        if (!user || !user.passwordHash) {
          throw new Error('Invalid email or password');
        }

        const isPasswordValid = await bcrypt.compare(
          credentials.password,
          user.passwordHash
        );

        if (!isPasswordValid) {
          throw new Error('Invalid email or password');
        }

        return {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
        };
      },
    }),
    // Google OAuth (optional -- requires env vars)
    ...(process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET
      ? [
          GoogleProvider({
            clientId: process.env.GOOGLE_CLIENT_ID,
            clientSecret: process.env.GOOGLE_CLIENT_SECRET,
          }),
        ]
      : []),
  ],
  session: {
    strategy: 'jwt',
    maxAge: 30 * 24 * 60 * 60, // 30 days
  },
  pages: {
    signIn: '/auth/signin',
    signOut: '/auth/signout',
    error: '/auth/error',
  },
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.id = user.id;
        token.role = (user as UserWithRole).role || 'USER';
      }
      return token;
    },
    async session({ session, token }) {
      if (session.user) {
        const extendedSession = session as ExtendedSession;
        extendedSession.user.id = token.id as string;
        extendedSession.user.role = (token.role as string) || 'USER';
        return extendedSession;
      }
      return session;
    },
  },
  debug: process.env.NODE_ENV === 'development',
};

export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, 12);
}

export async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

export function isAdmin(session: ExtendedSession | null): boolean {
  return session?.user?.role === 'ADMIN';
}

export function isAuthenticated(session: Session | null): boolean {
  return !!session?.user;
}
```

### `app/api/auth/[...nextauth]/route.ts` -- API route
```typescript
import NextAuth from 'next-auth';
import { authOptions } from '@/lib/auth';

const handler = NextAuth(authOptions);
export { handler as GET, handler as POST };
```

### Prisma Schema Addition
```prisma
model User {
  id            String    @id @default(cuid())
  email         String    @unique
  name          String?
  passwordHash  String?
  role          String    @default("USER")  // USER, ADMIN, INSTRUCTOR
  image         String?
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt

  accounts      Account[]
  sessions      Session[]
}
```

## Key Design Decisions
1. **JWT strategy over database sessions** -- better for serverless (no DB query per request)
2. **bcryptjs with cost factor 12** -- good balance of security vs speed
3. **Optional Google OAuth** -- only registers provider if env vars exist (no crash if missing)
4. **Generic error messages** -- "Invalid email or password" prevents user enumeration
5. **Role stored in JWT** -- available on every request without DB call

## Projects That Need This Pattern
- **Sports** (D) -- zero auth currently, critical need
- **Acquisition System** (B-) -- 20+ endpoints, zero auth middleware
- **Calc** (C+) -- monitoring endpoints exposed publicly
- **Affiliate/TheStackGuide** (B-) -- admin dashboard has no auth
- **Discovery** (C+) -- premium paywall needs auth enforcement
