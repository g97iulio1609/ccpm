import Stripe from 'stripe';

const stripeSecretKey = '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';
const stripeWebhookSecret = 'whsec_Btsi8YKXYiM1OZA3FxEhVD2IImblVB0O';

if (!stripeSecretKey || !stripeWebhookSecret) {
  throw new Error('Stripe secret keys are not set in environment variables.');
}

export const stripe = new Stripe(stripeSecretKey, {
  apiVersion: '2024-06-20',
});

export { stripeWebhookSecret }; 