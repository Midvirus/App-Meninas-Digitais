package com.meninasdigitais;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class MeninasDigitaisBackendApplication {

	public static void main(String[] args) {
		SpringApplication.run(MeninasDigitaisBackendApplication.class, args);
	}

}
