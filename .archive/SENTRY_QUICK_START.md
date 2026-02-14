# 🚀 Sentry Quick Start - 5 Minutes to Production Monitoring

## ✅ Status: Configuration Complete

Both projects are **fully configured** and ready for Sentry. Just add your DSN keys to start monitoring!

---

## 📋 Checklist

### For Both Projects

- [x] Sentry SDKs installed
- [x] Configuration files created
- [x] Error tracking integrated
- [x] Performance monitoring added
- [x] Documentation written
- [ ] **DSN keys added** ← YOU ARE HERE
- [ ] Error tracking tested
- [ ] Alerts configured

---

## ⚡ Quick Setup (5 minutes)

### Step 1: Create Sentry Account (1 minute)

1. Go to https://sentry.io
2. Sign up (free - 5,000 events/month)
3. Verify email

### Step 2: Create Projects (2 minutes)

**Project 1: AI Sales Platform**
1. Click "Create Project"
2. Choose platform: **Node.js**
3. Name: **AI Sales Platform**
4. Click "Create Project"
5. **Copy the DSN** (looks like: `https://abc123@o456.ingest.sentry.io/789`)

**Project 2: Church Website**
1. Click "Create Project" again
2. Choose platform: **Next.js**
3. Name: **Church Website**
4. Click "Create Project"
5. **Copy the DSN**

### Step 3: Add DSN Keys (1 minute)

**AI Sales Platform:**
```bash
cd /mnt/e/projects/ai-sales-platform

# Add to .env file:
echo "SENTRY_DSN=your-dsn-here" >> .env
```

**Church Website:**
```bash
cd /mnt/e/projects/church

# Add to .env.local file:
echo "SENTRY_DSN=your-dsn-here" >> .env.local
echo "NEXT_PUBLIC_SENTRY_DSN=your-dsn-here" >> .env.local
```

### Step 4: Test (1 minute)

**AI Platform:**
```bash
npm run dev

# Should see: "✅ Sentry initialized for error monitoring"

# Trigger test error:
curl -X POST http://localhost:3000/api/agent/execute \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Church:**
```bash
npm run dev

# Visit http://localhost:3000
# Open browser console and type:
throw new Error('Test error');
```

### Step 5: Verify in Sentry (30 seconds)

1. Go to your Sentry dashboard
2. Click on project
3. Go to "Issues" tab
4. You should see your test errors! 🎉

---

## 🎯 What You Get

### Immediate Benefits

- ✅ Automatic error capture
- ✅ Real-time notifications
- ✅ Stack traces with line numbers
- ✅ User impact tracking
- ✅ Performance monitoring
- ✅ 30-day error history

### Advanced Features (Configure Later)

- 📧 Email alerts on new errors
- 💬 Slack integration
- 📊 Custom dashboards
- 🔍 Source maps (readable stack traces)
- 📦 Release tracking
- 👥 User feedback

---

## 📖 Full Documentation

For detailed setup, usage examples, and troubleshooting:

1. **Comprehensive Guide**: `/mnt/e/projects/SENTRY_INTEGRATION_GUIDE.md`
2. **AI Platform Setup**: `/mnt/e/projects/ai-sales-platform/SENTRY_SETUP.md`
3. **Church Setup**: `/mnt/e/projects/church/SENTRY_SETUP.md`
4. **Complete Report**: `/mnt/e/projects/SENTRY_INTEGRATION_COMPLETE.md`

---

## 💡 Pro Tips

### 1. Set Up Alerts First
- Go to Settings → Alerts
- Create "New Issue" alert
- Get notified when bugs occur

### 2. Add User Context
```typescript
import { setUser } from '@/lib/sentry';

// On login
setUser({
  id: user.id,
  email: user.email
});
```

### 3. Use Breadcrumbs
```typescript
import { addBreadcrumb } from '@/lib/sentry';

addBreadcrumb({
  message: 'User clicked donate button',
  category: 'user-action',
  data: { amount: 100 }
});
```

---

## ❓ Troubleshooting

### Errors Not Showing Up?

1. **Check DSN is set:**
   ```bash
   echo $SENTRY_DSN
   ```

2. **Check initialization:**
   - AI Platform: Look for "Sentry initialized" log
   - Church: Check browser console for Sentry

3. **Try triggering an error:**
   ```bash
   # AI Platform
   curl -X POST http://localhost:3000/api/test-error

   # Church (browser console)
   throw new Error('Test');
   ```

### Still Having Issues?

Check the full documentation for detailed troubleshooting:
- `/mnt/e/projects/SENTRY_INTEGRATION_GUIDE.md`

---

## 🎉 You're Done!

That's it! Your projects now have enterprise-grade error monitoring.

**Next Steps:**
1. ✅ Add DSN keys (5 minutes)
2. ✅ Test error tracking
3. ✅ Configure email alerts
4. ⏳ Enjoy peace of mind knowing about bugs before users do! 😊

---

**Questions?** Check the documentation files listed above.

**Happy monitoring!** 🔍✨
