package com.meninasdigitais.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

// RF13
@Data
public class DestaqueRequest {
    @NotBlank private String comentarioDestaque;
}