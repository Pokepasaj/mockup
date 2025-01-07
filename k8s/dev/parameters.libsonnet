{
    name: "book-review-app",
    labels: "book-review-app",
    replicas: 1,
    image: 'book-review-app:latest',
    port: 8080,
    targetPort: 8080,
    selector: "book-review-app",
    namespace: 'book-review-app'

}