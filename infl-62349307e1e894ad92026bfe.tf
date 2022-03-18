resource "kubernetes_service" "payment" {
	metadata {
		name = "payment"
		namespace = "robot-shop"
	}
	spec {
		cluster_ip = "172.20.147.45"
		session_affinity = "None"
		type = "ClusterIP"
	}
}