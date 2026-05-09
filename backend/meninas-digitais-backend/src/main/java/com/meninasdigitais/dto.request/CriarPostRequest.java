package com.meninasdigitais.dto.request;

import com.meninasdigitais.enums.PostCategory;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

// RF15
@Data
public class CriarPostRequest {
    @NotBlank private String titulo;
    @NotBlank private String texto;
    private String linkExterno;
    @NotNull  private PostCategory categoria;
}