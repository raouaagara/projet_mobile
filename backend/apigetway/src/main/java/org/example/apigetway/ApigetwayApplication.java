package org.example.apigetway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
@EnableDiscoveryClient
public class ApigetwayApplication {

    public static void main(String[] args) {
        SpringApplication.run(ApigetwayApplication.class, args);
    }

    @Bean
    public RouteLocator gatewayroute(RouteLocatorBuilder builder){
        return builder.routes()
                // WebSocket upgrades must be proxied as ws:// (the mobile STOMP client has no SockJS
                // HTTP fallback). Declared first: the plain http routes below also match these paths.
                .route("idroutechatws", r -> r.path("/ws/**").and().header("Upgrade", "(?i)websocket")
                        .uri("lb:ws://MSCOMMUNICATION"))
                .route("idroutesupportws", r -> r.path("/ws-support/**").and().header("Upgrade", "(?i)websocket")
                        .uri("lb:ws://TECHNICALSUPPORTMS"))

                .route("idroute1project", r -> r.path("/Project/**")
                        .uri("lb://PROJECTMICROSERVICE"))
                .route("idroute1user", r -> r.path("/users/**")
                        .uri("lb://USERMICROSERVICE"))
                .route("idroute1contract", r -> r.path("/Contract/**")
                        .uri("lb://PROJECTMICROSERVICE"))

                .route("idroute1CompetanceETreview", r -> r.path("/Competance/**")
                        .uri("lb://MSCOMPETENCEANDREVIEW"))

                .route("idroute2CompetanceETreview", r -> r.path("/Review/**")
                        .uri("lb://MSCOMPETENCEANDREVIEW"))

                .route("idroutepayment", r -> r.path("/api/payments/**", "/api/disputes/**")
                        .uri("lb://PAIEMENTMS"))

                .route("idroutesupport", r -> r.path("/api/tickets/**", "/ws-support/**")
                        .uri("lb://TECHNICALSUPPORTMS"))

                // /uploads/**: chat attachments (images, PDFs), so phones can open them through the gateway
                .route("idroutechat", r -> r.path("/chat/**", "/ws/**", "/uploads/**")
                        .uri("lb://MSCOMMUNICATION"))

                .route("idroutesubscription", r -> r.path("/Subscription/**", "/api/promo-codes/**", "/api/rewards/**")
                        .uri("lb://SUBSCRIPTIONMICROSERVICE"))

                .route("idroutereferral", r -> r.path("/Referral/**", "/api/donations/**", "/api/wallet/**")
                        .uri("lb://REFERRALMICROSERVICE"))

                .route("idrouteskilltests", r -> r.path("/SkillTests/**")
                        .uri("lb://SKILLTESTSMICROSERVICE"))

                .route("idroutecommunity", r -> r.path("/api/groups/**", "/api/group-members/**", "/api/events/**",
                                "/api/clubs/**", "/api/posts/**", "/api/comments/**", "/api/reactions/**",
                                "/api/comment-reactions/**")
                        .uri("lb://COMMUNITYMICROSERVICE"))

                .build();
    }

}
