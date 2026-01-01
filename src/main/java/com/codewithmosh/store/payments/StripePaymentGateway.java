package com.codewithmosh.store.payments;

import com.codewithmosh.store.orders.Order;
import com.codewithmosh.store.orders.OrderItem;
import com.codewithmosh.store.orders.PaymentStatus;
import com.stripe.exception.SignatureVerificationException;
import com.stripe.exception.StripeException;
import com.stripe.model.Event;
import com.stripe.model.checkout.Session;
import com.stripe.net.Webhook;
import com.stripe.param.checkout.SessionCreateParams;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.math.BigDecimal;
import java.util.Optional;

@Service
public class StripePaymentGateway implements PaymentGateway {
    @Value("${websiteUrl}")
    private String websiteUrl;

    @Value("${stripe.webhookSecretKey}")
    private String webhookSecretKey;

    @Override
    public CheckoutSession createCheckoutSession(Order order) {
        try {
            var builder = SessionCreateParams.builder()
                    .setMode(SessionCreateParams.Mode.PAYMENT)
                    .setSuccessUrl(websiteUrl + "/checkout-success?orderId=" + order.getId())
                    .setCancelUrl(websiteUrl + "/checkout-cancel")
                    .setPaymentIntentData(createPaymentIntent(order));

            order.getItems().forEach(item -> {
                var lineItem = createLineItem(item);
                builder.addLineItem(lineItem);
            });

            var session = Session.create(builder.build());
            return new CheckoutSession(session.getUrl());
        }
        catch (StripeException ex) {
            System.out.println(ex.getMessage());
            throw new PaymentException();
        }
    }

    private static SessionCreateParams.PaymentIntentData createPaymentIntent(Order order) {
        return SessionCreateParams.PaymentIntentData.builder()
                .putMetadata("order_id", order.getId().toString())
                .build();
    }

    @Override
    public Optional<PaymentResult> parseWebhookRequest(WebhookRequest request) {
        try {
            var payload = request.getPayload();
            var signature = request.getHeaders().get("stripe-signature");
            var event = Webhook.constructEvent(payload, signature, webhookSecretKey);

            return switch (event.getType()) {
                case "payment_intent.succeeded" ->
                    Optional.of(new PaymentResult(extractOrderId(event), PaymentStatus.PAID));

                case "payment_intent.payment_failed" ->
                    Optional.of(new PaymentResult(extractOrderId(event), PaymentStatus.FAILED));

                default -> Optional.empty();
            };
        } catch (SignatureVerificationException e) {
            throw new PaymentException("Invalid signature");
        }
    }

    private Long extractOrderId(Event event) {
        try {
            ObjectMapper mapper = new ObjectMapper();
            JsonNode root = mapper.readTree(event.toJson());

            JsonNode orderId = root.path("data").path("object").path("metadata").path("order_id");

            if (!orderId.isMissingNode() && !orderId.isNull()) {
                String orderIdStr = orderId.asText();
                return Long.valueOf(orderIdStr);
            }

            throw new PaymentException("Order ID not found in payment intent metadata");

        } catch (NumberFormatException e) {
            throw new PaymentException("Invalid order ID format");
        } catch (Exception e) {
            throw new PaymentException("Failed to extract order ID: " + e.getMessage());
        }
    }

    private SessionCreateParams.LineItem createLineItem(OrderItem item) {
        return SessionCreateParams.LineItem.builder()
                .setQuantity(Long.valueOf(item.getQuantity()))
                .setPriceData(createPriceData(item))
                .build();
    }

    private SessionCreateParams.LineItem.PriceData createPriceData(OrderItem item) {
        return SessionCreateParams.LineItem.PriceData.builder()
                .setCurrency("usd")
                .setUnitAmountDecimal(
                    item.getUnitPrice().multiply(BigDecimal.valueOf(100)))
                .setProductData(createProductData(item))
                .build();
    }

    private SessionCreateParams.LineItem.PriceData.ProductData createProductData(OrderItem item) {
        return SessionCreateParams.LineItem.PriceData.ProductData.builder()
                .setName(item.getProduct().getName())
                .build();
    }
}
