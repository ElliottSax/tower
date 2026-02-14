# ⚠️ SECURITY ALERT - IMMEDIATE ACTION REQUIRED

## Your API Keys Were Exposed

You posted your API keys in plain text in a conversation. While I've secured them in `.env` files, **you must rotate these keys immediately**.

---

## 🚨 IMMEDIATE ACTIONS (Do This Now!)

### 1. Rotate DeepSeek Key

```bash
# Go to: https://platform.deepseek.com/api_keys
# 1. Click "Delete" on the exposed key
# 2. Create new key
# 3. Update .env with new key
```

**Old key (EXPOSED - DELETE THIS):**
- Starts with: `sk-8b0ff3a7...`
- Status: ⚠️ COMPROMISED

### 2. Rotate Hugging Face Key

```bash
# Go to: https://huggingface.co/settings/tokens
# 1. Revoke the exposed token
# 2. Create new token with same permissions
# 3. Update .env with new token
```

**Old token (EXPOSED - DELETE THIS):**
- Starts with: `hf_jteiHS...`
- Status: ⚠️ COMPROMISED

---

## 🔒 HOW TO SECURELY MANAGE SECRETS

### Never Do This:
```bash
❌ Post keys in chat/email/Slack
❌ Commit .env to git
❌ Share keys in screenshots
❌ Store in plaintext files in Dropbox/Drive
❌ Hardcode in source code
```

### Always Do This:
```bash
✅ Use .env files (in .gitignore)
✅ Use environment variables
✅ Use secret managers (AWS Secrets Manager, HashiCorp Vault)
✅ Rotate keys regularly
✅ Use different keys for dev/prod
✅ Set key permissions (chmod 600 .env)
```

---

## ✅ What I Did to Secure Your Keys

1. **Added to `.env`** (never committed to git)
   ```bash
   # File: /mnt/e/projects/quant-discovery/.env
   # Permissions: 600 (owner read/write only)
   DEEPSEEK_API_KEY=sk-***  # Hidden in file
   HF_API_KEY=hf_***        # Hidden in file
   ```

2. **Created `.gitignore`**
   ```
   .env
   .env.local
   .env.*.local
   ```
   This prevents accidental git commits of secrets.

3. **Created `.env.example`**
   Template without actual keys for other developers.

4. **Set file permissions**
   ```bash
   chmod 600 .env  # Only you can read/write
   ```

---

## 🔧 Verify Security

Run these commands to check:

```bash
cd /mnt/e/projects/quant-discovery

# 1. Check .env is in .gitignore
grep -q "^\.env$" .gitignore && echo "✅ .env in .gitignore" || echo "❌ NOT PROTECTED"

# 2. Check file permissions
ls -la .env | grep -q "rw-------" && echo "✅ Permissions secure" || echo "⚠️ Fix with: chmod 600 .env"

# 3. Make sure .env is NOT in git
git check-ignore .env && echo "✅ .env ignored by git" || echo "❌ DANGER: .env will be committed!"

# 4. Check for accidentally committed secrets
git log --all --full-history -- .env && echo "⚠️ .env was committed!" || echo "✅ No .env in git history"
```

---

## 📋 Security Checklist

After rotating keys:

- [ ] Deleted old DeepSeek key from platform
- [ ] Revoked old HuggingFace token
- [ ] Created new keys
- [ ] Updated `.env` with new keys
- [ ] Verified `.env` is in `.gitignore`
- [ ] Verified `.env` has 600 permissions
- [ ] Tested new keys work: `python -c "from discovery.utils.llm_service import get_llm_service; llm = get_llm_service(); print('✅ Keys work!')"`
- [ ] Set up key rotation reminder (every 90 days)
- [ ] Documented where keys are stored for team

---

## 🎓 Best Practices Going Forward

### For Development:
```bash
# Use direnv (auto-loads .env when you cd into directory)
brew install direnv  # or apt-get install direnv
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
echo "export $(cat .env | xargs)" > .envrc
direnv allow
```

### For Production:
```bash
# Use a secrets manager
# AWS Secrets Manager, Google Secret Manager, HashiCorp Vault, etc.

# Example with AWS:
aws secretsmanager create-secret \
  --name quant-discovery/deepseek-key \
  --secret-string "sk-new-key"

# Retrieve in code:
import boto3
secret = boto3.client('secretsmanager').get_secret_value(SecretId='quant-discovery/deepseek-key')
```

### For Team Collaboration:
```bash
# Use 1Password, LastPass, or Bitwarden for team secrets
# Never share keys via:
# - Email
# - Slack
# - Chat
# - Screenshots
```

---

## 💰 Cost Impact

**Good news:** Both services have free tiers, so even if someone found your keys:

**DeepSeek:**
- $5 free credits
- Max loss: $5
- Can set spending limits

**Hugging Face:**
- Free tier: 30K requests/month
- Max loss: Minimal (rate limited)
- Can revoke token anytime

**Still, rotate them now!**

---

## 🔐 Key Rotation Script

Save this for future rotations:

```bash
#!/bin/bash
# rotate_keys.sh

echo "🔄 Rotating API keys..."

# Backup old .env
cp .env .env.backup.$(date +%Y%m%d)

# Prompt for new keys
read -sp "Enter new DeepSeek key: " DEEPSEEK_KEY
echo
read -sp "Enter new HuggingFace token: " HF_KEY
echo

# Update .env
sed -i.bak "s/DEEPSEEK_API_KEY=.*/DEEPSEEK_API_KEY=$DEEPSEEK_KEY/" .env
sed -i.bak "s/HF_API_KEY=.*/HF_API_KEY=$HF_KEY/" .env

# Test
python -c "from discovery.utils.llm_service import get_llm_service; get_llm_service()" && echo "✅ New keys work!" || echo "❌ Keys failed!"

# Secure permissions
chmod 600 .env

echo "✅ Keys rotated successfully!"
echo "⚠️ Don't forget to revoke old keys from provider dashboards!"
```

---

## 📞 If Keys Were Already Used Maliciously

Monitor for:

1. **Unexpected charges**
   - DeepSeek: https://platform.deepseek.com/usage
   - HuggingFace: https://huggingface.co/settings/billing

2. **Unusual API calls**
   - Check logs for requests you didn't make
   - Look for spikes in usage

3. **Contact support if suspicious activity**
   - DeepSeek: support@deepseek.com
   - HuggingFace: Use contact form on site

---

## ✅ All Set!

Your keys are now secured in `.env` files that won't be committed to git.

**Next steps:**
1. Rotate the exposed keys (links above)
2. Update `.env` with new keys
3. Test: `python -c "from discovery.utils.llm_service import get_llm_service; print('✅ Works!')"`
4. Never share keys in plain text again!

---

**Remember:** Secrets in environment variables, never in code! 🔒
