package com.meninasdigitais.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

// RF08 - feedback da tutora
@Data
public class FeedbackRespostaRequest {
    @NotBlank private String feedback;
    @NotNull  private boolean aprovado; // true = VALIDADO, false = revisão necessária
}