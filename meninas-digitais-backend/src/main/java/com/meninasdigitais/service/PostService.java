package com.meninasdigitais.service;

import com.meninasdigitais.dto.request.CriarPostRequest;
import com.meninasdigitais.entity.PostCuriosidade;
import com.meninasdigitais.entity.Usuario;
import com.meninasdigitais.enums.PostCategory;
import com.meninasdigitais.repository.PostCuriosidadeRepository;
import com.meninasdigitais.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class PostService {

    private final PostCuriosidadeRepository postRepository;
    private final UsuarioRepository usuarioRepository;

    // RF15 - publicar post
    public PostCuriosidade publicar(CriarPostRequest req, Usuario tutora, String imagemUrl) {
        PostCuriosidade post = PostCuriosidade.builder()
                .titulo(req.getTitulo())
                .texto(req.getTexto())
                .imagemUrl(imagemUrl)
                .linkExterno(req.getLinkExterno())
                .categoria(req.getCategoria())
                .tutora(tutora)
                .build();
        return postRepository.save(post);
    }

    // RF14 - listar posts
    public List<PostCuriosidade> listar() {
        return postRepository.findByAtivoTrueOrderByCriadoEmDesc();
    }

    public List<PostCuriosidade> listarPorCategoria(PostCategory categoria) {
        return postRepository.findByCategoriaAndAtivoTrue(categoria);
    }

    // RF16 - curtir post
    public PostCuriosidade curtir(Long postId, Usuario tutoranda) {
        PostCuriosidade post = postRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post não encontrado."));
        boolean jaCurtiu = post.getCurtidas().stream().anyMatch(u -> u.getId().equals(tutoranda.getId()));
        if (jaCurtiu) {
            post.getCurtidas().removeIf(u -> u.getId().equals(tutoranda.getId()));
        } else {
            post.getCurtidas().add(tutoranda);
        }
        return postRepository.save(post);
    }

    // RF18 - remover post (admin)
    public void remover(Long postId) {
        PostCuriosidade post = postRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post não encontrado."));
        post.setAtivo(false);
        postRepository.save(post);
    }
}