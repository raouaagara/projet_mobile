package org.example.ms_competenceandreview.Feign;


import feign.codec.Decoder;
import feign.jackson.JacksonDecoder;
import org.springframework.context.annotation.Bean;

public class FeignConfig {
    @Bean
    public Decoder feignDecoder() {
        return new JacksonDecoder();
    }
}
