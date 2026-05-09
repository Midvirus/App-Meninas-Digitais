package com.meninasdigitais.dto.request;

import com.meninasdigitais.enums.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

// RF01 - cadastro pelo admin
@Data
public class CadastroUsuarioRequest {

    @NotBlank(message = "Nome é obrigatório")
    private String nome;

    @NotBlank(message = "Email é obrigatório")
    @Email(message = "Email inválido")
    private String email;

    @NotBlank(message = "Senha é obrigatória")
    private String senha;

    private String escolaInstituicao;

    @NotNull(message = "Papel é obrigatório")
    private Role role;
}