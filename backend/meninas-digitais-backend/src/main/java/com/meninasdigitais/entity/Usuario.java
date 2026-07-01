package com.meninasdigitais.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.meninasdigitais.enums.Role;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;

/**
 * Entidade principal de usuário.
 * Cobre RF01 (cadastro com papel), RF02 (perfil editável), RF19 (gerenciamento
 * de usuários).
 */
@Entity
@Table(name = "usuarios")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Usuario implements UserDetails {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nome;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    @JsonIgnore
    private String senha;

    @Column(name = "escola_instituicao")
    private String escolaInstituicao;

    @Column(name = "foto_perfil_url")
    private String fotoPerfilUrl;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    @Column(nullable = false)
    @Builder.Default
    private boolean ativo = true;

    @Column(name = "criado_em", updatable = false)
    private LocalDateTime criadoEm;

    @Column(name = "atualizado_em")
    private LocalDateTime atualizadoEm;

    // RF20 - autorização para publicar nome/conteúdo da tutoranda
    @Column(name = "autorizacao_publicacao")
    private Boolean autorizacaoPublicacao;

    @Column(name = "autorizacao_respondida_em")
    private LocalDateTime autorizacaoRespondidaEm;

    // Relacionamento tutora com tutorandas
    @ManyToOne
    @JoinColumn(name = "tutora_id")
    @JsonIgnoreProperties({"senha", "authorities", "tutora"})
    private Usuario tutora;

    @Transient
    private Integer postsFeitos;

    @Transient
    private Integer desafiosCriados;

    @Transient
    private Integer quantidadeTutorandas;

    @Transient
    private Integer desafiosFeitos;

    @Transient
    private Integer respostasCorretas;

    @Transient
    private Double taxaConclusao;

    @PrePersist
    protected void onCreate() {
        criadoEm = LocalDateTime.now();
        atualizadoEm = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        atualizadoEm = LocalDateTime.now();
    }

    // Spring Security

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + role.name()));
    }

    @Override
    @JsonIgnore
    public String getPassword() {
        return senha;
    }

    @Override
    public String getUsername() {
        return email;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return ativo;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return ativo;
    }
}