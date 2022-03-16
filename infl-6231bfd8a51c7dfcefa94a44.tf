resource "kubernetes_service" "ratings" {
	metadata {
		name = "ratings"
		namespace = "robot-shop"
	}
	spec {
		cluster_ip = "172.20.217.0"
		session_affinity = "None"
		type = "ClusterIP"
	}
}