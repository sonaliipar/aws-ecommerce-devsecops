package com.example.ecommerce;

import java.math.BigDecimal;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/products")
public class ProductController {
    public record Product(long id, String name, BigDecimal price) {}

    @GetMapping
    public List<Product> products() {
        return List.of(
            new Product(1, "Laptop", new BigDecimal("799.00")),
            new Product(2, "Headphones", new BigDecimal("49.00")),
            new Product(3, "Keyboard", new BigDecimal("39.00"))
        );
    }
}
