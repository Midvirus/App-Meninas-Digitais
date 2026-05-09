package com.meninasdigitais.entity;

import com.meninasdigitais.enums.PostCategory;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Post de curiosidades publicado pela Tutora.
 * RF14 - exibição na seção de curiosidades.
 * RF15 - publicação com título, texto, imagem, link e categoria.
 * RF16 - curtidas das tutorandas.
 */
@Entity
@Table(name = "posts_curiosidades")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PostCuriosidade {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String titulo;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String texto;

    @Column(name = "imagem_url")
    private String imagemUrl;

    @Column(name = "link_externo")
    private String linkExterno;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PostCategory categoria;

    @Column(nullable = false)
    @Builder.Default
    private boolean ativo = true;

    @ManyToOne
    @JoinColumn(name = "tutora_id", nullable = false)
    private Usuario tutora;

    // RF16 - curtidas (tutorandas que curtiram)
    @ManyToMany
    @JoinTable(
            name = "curtidas_posts",
            joinColumns = @JoinColumn(name = "post_id"),
            inverseJoinColumns = @JoinColumn(name = "tutoranda_id")
    )
    @Builder.Default
    private List<Usuario> curtidas = new ArrayList<>();

    @Column(name = "criado_em", updatable = false)
    private LocalDateTime criadoEm;

    @Column(name = "atualizado_em")
    private LocalDateTime atualizadoEm;

    @PrePersist
    protected void onCreate() {
        criadoEm = LocalDateTime.now();
        atualizadoEm = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        atualizadoEm = LocalDateTime.now();
    }
}