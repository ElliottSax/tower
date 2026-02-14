/**
 * Email Sender Service
 *
 * Unified interface for sending emails across multiple providers.
 * Supports Resend, SendGrid, and SMTP.
 */

import nodemailer from 'nodemailer';
import axios from 'axios';

export interface SendEmailParams {
  from: string;
  to: string;
  subject: string;
  html: string;
  text?: string;
  replyTo?: string;
  accountId: string;
  provider: 'resend' | 'sendgrid' | 'smtp';
}

export interface SendEmailResult {
  success: boolean;
  messageId?: string;
  error?: string;
}

/**
 * Send via Resend
 */
async function sendViaResend(params: SendEmailParams): Promise<SendEmailResult> {
  try {
    const response = await axios.post(
      'https://api.resend.com/emails',
      {
        from: params.from,
        to: params.to,
        subject: params.subject,
        html: params.html,
        text: params.text,
        reply_to: params.replyTo,
      },
      {
        headers: {
          'Authorization': `Bearer ${process.env.RESEND_API_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );

    return {
      success: true,
      messageId: response.data.id,
    };
  } catch (error: any) {
    console.error('[Resend] Error:', error.response?.data || error.message);
    return {
      success: false,
      error: error.response?.data?.message || error.message,
    };
  }
}

/**
 * Send via SendGrid
 */
async function sendViaSendGrid(params: SendEmailParams): Promise<SendEmailResult> {
  try {
    const response = await axios.post(
      'https://api.sendgrid.com/v3/mail/send',
      {
        personalizations: [{
          to: [{ email: params.to }],
          subject: params.subject,
        }],
        from: { email: params.from },
        content: [
          {
            type: 'text/html',
            value: params.html,
          },
        ],
        reply_to: params.replyTo ? { email: params.replyTo } : undefined,
      },
      {
        headers: {
          'Authorization': `Bearer ${process.env.SENDGRID_API_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );

    // SendGrid returns 202 Accepted with X-Message-Id header
    const messageId = response.headers['x-message-id'];

    return {
      success: true,
      messageId,
    };
  } catch (error: any) {
    console.error('[SendGrid] Error:', error.response?.data || error.message);
    return {
      success: false,
      error: error.response?.data?.errors?.[0]?.message || error.message,
    };
  }
}

/**
 * Send via SMTP (Nodemailer)
 */
async function sendViaSMTP(params: SendEmailParams): Promise<SendEmailResult> {
  try {
    // Create transport (in production, cache this per account)
    const transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST || 'smtp.gmail.com',
      port: parseInt(process.env.SMTP_PORT || '587', 10),
      secure: process.env.SMTP_PORT === '465', // true for 465, false for other ports
      auth: {
        user: process.env.SMTP_USERNAME,
        pass: process.env.SMTP_PASSWORD,
      },
    });

    const info = await transporter.sendMail({
      from: params.from,
      to: params.to,
      subject: params.subject,
      html: params.html,
      text: params.text,
      replyTo: params.replyTo,
    });

    return {
      success: true,
      messageId: info.messageId,
    };
  } catch (error: any) {
    console.error('[SMTP] Error:', error.message);
    return {
      success: false,
      error: error.message,
    };
  }
}

/**
 * Main send email function
 */
export async function sendEmail(params: SendEmailParams): Promise<SendEmailResult> {
  console.log(`[Email Sender] Sending via ${params.provider} to ${params.to}`);

  switch (params.provider) {
    case 'resend':
      return sendViaResend(params);

    case 'sendgrid':
      return sendViaSendGrid(params);

    case 'smtp':
      return sendViaSMTP(params);

    default:
      throw new Error(`Unsupported email provider: ${params.provider}`);
  }
}

/**
 * Validate email configuration for an account
 */
export async function validateEmailAccount(provider: string, apiKey?: string): Promise<boolean> {
  try {
    switch (provider) {
      case 'resend':
        const resendTest = await axios.get('https://api.resend.com/domains', {
          headers: { 'Authorization': `Bearer ${apiKey}` },
        });
        return resendTest.status === 200;

      case 'sendgrid':
        const sendgridTest = await axios.get('https://api.sendgrid.com/v3/user/profile', {
          headers: { 'Authorization': `Bearer ${apiKey}` },
        });
        return sendgridTest.status === 200;

      case 'smtp':
        // For SMTP, would need to test connection
        return true; // Assume valid for now

      default:
        return false;
    }
  } catch (error) {
    console.error(`[Email Sender] Validation failed for ${provider}:`, error);
    return false;
  }
}
