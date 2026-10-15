package com.ptit.devops.shop.controller;

import com.ptit.devops.shop.entity.Product;
import com.ptit.devops.shop.repository.ProductRepository;
import org.springframework.data.domain.Sort;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api")
public class ProductController {

    private final ProductRepository repository;

    public ProductController(ProductRepository repository) {
        this.repository = repository;
    }

    /** GET /api/products - danh sách sản phẩm */
    @GetMapping("/products")
    public List<Product> findAll() {
        return repository.findAll(Sort.by("id"));
    }
}
