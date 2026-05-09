package com.meninasdigitais.dto.request;

import com.meninasdigitais.enums.DifficultyLevel;
import com.meninasdigitais.enums.ResponseType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

// RF04
@Data
public class CriarDesafioRequest {
    @NotBlank private String titulo;
    @NotBlank private String descricao;
    @NotNull  private DifficultyLevel nivelDificuldade;
    private LocalDateTime prazoEntrega;
    @NotNull  private ResponseType tipoResposta;
    private String tags;
    // RF05
    private boolean paraTodasTutorandas = true;
    private List<Long> tutorandasEspecificasIds;
}