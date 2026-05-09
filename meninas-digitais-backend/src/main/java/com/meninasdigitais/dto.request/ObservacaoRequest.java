package com.meninasdigitais.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

// RF10
@Data
public class ObservacaoRequest {
    @NotBlank private String conteudo;
}