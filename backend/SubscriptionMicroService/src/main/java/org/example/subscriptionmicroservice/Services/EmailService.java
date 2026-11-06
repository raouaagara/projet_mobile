package org.example.subscriptionmicroservice.Services;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.example.subscriptionmicroservice.Entities.SubscriptionPlan;
import org.example.subscriptionmicroservice.Entities.UserSubscription;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import java.time.format.DateTimeFormatter;

@Service
public class EmailService {

    @Autowired
    private JavaMailSender mailSender;

    @Value("${app.email.from:noreply@catchopp.com}")
    private String fromEmail;

    @Value("${app.email.support:support@catchopp.com}")
    private String supportEmail;

    /**
     * Send subscription confirmation email
     */
    public void sendSubscriptionConfirmation(String toEmail, UserSubscription subscription) {
        try {
            System.out.println("📧 Attempting to send email to: " + toEmail);
            System.out.println("📧 Email configuration - From: " + fromEmail);
            System.out.println("📧 Email configuration - Support: " + supportEmail);
            
            if (toEmail == null || toEmail.isEmpty()) {
                System.err.println("❌ Cannot send email: toEmail is null or empty");
                return;
            }
            
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(fromEmail);
            helper.setTo(toEmail);
            helper.setSubject("🎉 Welcome to CatchOPP " + subscription.getPlan().getName() + "!");

            String htmlContent = buildSubscriptionEmail(subscription);
            helper.setText(htmlContent, true);

            System.out.println("📧 Sending email...");
            mailSender.send(message);
            System.out.println("✅ Subscription confirmation email sent successfully to: " + toEmail);
        } catch (MessagingException e) {
            System.err.println("❌ MessagingException - Failed to send email to: " + toEmail);
            System.err.println("❌ Error message: " + e.getMessage());
            e.printStackTrace();
        } catch (Exception e) {
            System.err.println("❌ Unexpected error sending email to: " + toEmail);
            System.err.println("❌ Error type: " + e.getClass().getName());
            System.err.println("❌ Error message: " + e.getMessage());
            e.printStackTrace();
        }
    }

    /**
     * Send subscription renewal reminder
     */
    public void sendRenewalReminder(String toEmail, UserSubscription subscription) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(fromEmail);
            helper.setTo(toEmail);
            helper.setSubject("⏰ Your CatchOPP Subscription Renewal Reminder");

            String htmlContent = buildRenewalReminderEmail(subscription);
            helper.setText(htmlContent, true);

            mailSender.send(message);
            System.out.println("✅ Renewal reminder email sent to: " + toEmail);
        } catch (MessagingException e) {
            System.err.println("❌ Failed to send renewal reminder to: " + toEmail);
            e.printStackTrace();
        }
    }

    /**
     * Send promo code earned notification
     */
    public void sendPromoCodeEarned(String toEmail, String userName, String promoCode, String rewardType, int discountValue) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(fromEmail);
            helper.setTo(toEmail);
            helper.setSubject("🎁 You Earned a Promo Code!");

            String htmlContent = buildPromoCodeEmail(userName, promoCode, rewardType, discountValue);
            helper.setText(htmlContent, true);

            mailSender.send(message);
            System.out.println("✅ Promo code email sent to: " + toEmail);
        } catch (MessagingException e) {
            System.err.println("❌ Failed to send promo code email to: " + toEmail);
            e.printStackTrace();
        }
    }

    /**
     * Build subscription confirmation email HTML
     */
    private String buildSubscriptionEmail(UserSubscription subscription) {
        SubscriptionPlan plan = subscription.getPlan();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("MMMM dd, yyyy");
        
        return """
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                    .header { background: linear-gradient(135deg, #10b981 0%%, #059669 100%%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
                    .content { background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px; }
                    .plan-box { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #10b981; }
                    .plan-name { font-size: 24px; font-weight: bold; color: #10b981; margin-bottom: 10px; }
                    .plan-price { font-size: 32px; font-weight: bold; color: #111827; }
                    .benefits { list-style: none; padding: 0; }
                    .benefits li { padding: 8px 0; padding-left: 25px; position: relative; }
                    .benefits li:before { content: "✓"; position: absolute; left: 0; color: #10b981; font-weight: bold; }
                    .info-row { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #e5e7eb; }
                    .info-label { font-weight: 600; color: #6b7280; }
                    .info-value { color: #111827; }
                    .button { display: inline-block; background: #10b981; color: white; padding: 12px 30px; text-decoration: none; border-radius: 8px; margin: 20px 0; }
                    .footer { text-align: center; padding: 20px; color: #6b7280; font-size: 14px; }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>🎉 Welcome to CatchOPP!</h1>
                        <p>Your subscription is now active</p>
                    </div>
                    <div class="content">
                        <p>Hi there,</p>
                        <p>Thank you for subscribing to CatchOPP! We're excited to have you on board.</p>
                        
                        <div class="plan-box">
                            <div class="plan-name">%s</div>
                            <div class="plan-price">$%s/%s</div>
                            <p style="color: #6b7280; margin-top: 10px;">%s</p>
                        </div>
                        
                        <h3>Subscription Details</h3>
                        <div class="info-row">
                            <span class="info-label">Start Date:</span>
                            <span class="info-value">%s</span>
                        </div>
                        <div class="info-row">
                            <span class="info-label">End Date:</span>
                            <span class="info-value">%s</span>
                        </div>
                        <div class="info-row">
                            <span class="info-label">Status:</span>
                            <span class="info-value">%s</span>
                        </div>
                        <div class="info-row">
                            <span class="info-label">Auto-Renew:</span>
                            <span class="info-value">%s</span>
                        </div>
                        
                        <h3>What's Included:</h3>
                        <ul class="benefits">
                            %s
                        </ul>
                        
                        <center>
                            <a href="http://localhost/SubscriptionDashboard" class="button">View Dashboard</a>
                        </center>
                        
                        <p style="margin-top: 30px;">If you have any questions, feel free to contact us at <a href="mailto:%s">%s</a></p>
                        
                        <p>Best regards,<br><strong>The CatchOPP Team</strong></p>
                    </div>
                    <div class="footer">
                        <p>© 2026 CatchOPP. All rights reserved.</p>
                        <p>This is an automated message, please do not reply to this email.</p>
                    </div>
                </div>
            </body>
            </html>
            """.formatted(
                plan.getName(),
                plan.getPrice(),
                plan.getDuration(),
                plan.getDescription(),
                subscription.getStartDate().format(formatter),
                subscription.getEndDate().format(formatter),
                subscription.getStatus(),
                subscription.getAutoRenew() ? "Enabled" : "Disabled",
                formatBenefits(plan.getBenefits()),
                supportEmail,
                supportEmail
            );
    }

    /**
     * Build renewal reminder email HTML
     */
    private String buildRenewalReminderEmail(UserSubscription subscription) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("MMMM dd, yyyy");
        
        return """
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                    .header { background: linear-gradient(135deg, #fbbf24 0%%, #f59e0b 100%%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
                    .content { background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px; }
                    .alert-box { background: #fef3c7; border: 2px solid #fbbf24; padding: 20px; border-radius: 8px; margin: 20px 0; }
                    .button { display: inline-block; background: #10b981; color: white; padding: 12px 30px; text-decoration: none; border-radius: 8px; margin: 20px 0; }
                    .footer { text-align: center; padding: 20px; color: #6b7280; font-size: 14px; }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>⏰ Subscription Renewal Reminder</h1>
                    </div>
                    <div class="content">
                        <p>Hi there,</p>
                        <p>Your <strong>%s</strong> subscription is expiring soon!</p>
                        
                        <div class="alert-box">
                            <h3 style="margin-top: 0;">Expiration Date: %s</h3>
                            <p>Your subscription will automatically renew if auto-renew is enabled.</p>
                        </div>
                        
                        <p>To continue enjoying all the benefits, make sure your payment method is up to date.</p>
                        
                        <center>
                            <a href="http://localhost/SubscriptionDashboard" class="button">Manage Subscription</a>
                        </center>
                        
                        <p style="margin-top: 30px;">Questions? Contact us at <a href="mailto:%s">%s</a></p>
                        
                        <p>Best regards,<br><strong>The CatchOPP Team</strong></p>
                    </div>
                    <div class="footer">
                        <p>© 2026 CatchOPP. All rights reserved.</p>
                    </div>
                </div>
            </body>
            </html>
            """.formatted(
                subscription.getPlan().getName(),
                subscription.getEndDate().format(formatter),
                supportEmail,
                supportEmail
            );
    }

    /**
     * Build promo code earned email HTML
     */
    private String buildPromoCodeEmail(String userName, String promoCode, String rewardType, int discountValue) {
        return """
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                    .header { background: linear-gradient(135deg, #10b981 0%%, #059669 100%%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
                    .content { background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px; }
                    .code-box { background: white; padding: 30px; border-radius: 8px; margin: 20px 0; text-align: center; border: 3px dashed #10b981; }
                    .code { font-size: 32px; font-weight: bold; color: #10b981; letter-spacing: 3px; font-family: 'Courier New', monospace; }
                    .discount { font-size: 48px; font-weight: bold; color: #10b981; margin: 20px 0; }
                    .button { display: inline-block; background: #10b981; color: white; padding: 12px 30px; text-decoration: none; border-radius: 8px; margin: 20px 0; }
                    .footer { text-align: center; padding: 20px; color: #6b7280; font-size: 14px; }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>🎁 Congratulations!</h1>
                        <p>You've earned a promo code!</p>
                    </div>
                    <div class="content">
                        <p>Hi %s,</p>
                        <p>Great news! You've earned a promo code for: <strong>%s</strong></p>
                        
                        <div class="code-box">
                            <div class="discount">%d%% OFF</div>
                            <p style="color: #6b7280; margin: 10px 0;">Your Promo Code:</p>
                            <div class="code">%s</div>
                            <p style="color: #6b7280; margin-top: 20px; font-size: 14px;">Valid for 30 days</p>
                        </div>
                        
                        <p>Use this code on your next subscription renewal to save money!</p>
                        
                        <center>
                            <a href="http://localhost/rewards" class="button">View My Rewards</a>
                        </center>
                        
                        <p style="margin-top: 30px; font-size: 14px; color: #6b7280;">
                            <strong>Note:</strong> This code can only be used once and is valid for future subscriptions only.
                        </p>
                        
                        <p>Best regards,<br><strong>The CatchOPP Team</strong></p>
                    </div>
                    <div class="footer">
                        <p>© 2026 CatchOPP. All rights reserved.</p>
                    </div>
                </div>
            </body>
            </html>
            """.formatted(
                userName,
                rewardType,
                discountValue,
                promoCode
            );
    }

    /**
     * Format benefits list for email
     */
    private String formatBenefits(String benefits) {
        if (benefits == null || benefits.isEmpty()) {
            return "<li>Full access to all features</li>";
        }
        
        String[] benefitArray = benefits.split(",");
        StringBuilder html = new StringBuilder();
        for (String benefit : benefitArray) {
            html.append("<li>").append(benefit.trim()).append("</li>");
        }
        return html.toString();
    }
}

