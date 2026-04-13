package http

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/arslanmaratbekov/ap2-assignment2/internal/order/domain"
	"github.com/arslanmaratbekov/ap2-assignment2/internal/order/usecase"
)

type Handler struct {
	orderUseCase *usecase.OrderUseCase
}

func NewHandler(orderUseCase *usecase.OrderUseCase) *Handler {
	return &Handler{orderUseCase: orderUseCase}
}

func (h *Handler) RegisterRoutes(router *gin.Engine) {
	router.POST("/orders", h.CreateOrder)
	router.GET("/orders/:id", h.GetOrder)
	router.PATCH("/orders/:id/status", h.UpdateOrderStatus)
}

func (h *Handler) CreateOrder(c *gin.Context) {
	var input domain.CreateOrderInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	order, err := h.orderUseCase.CreateOrder(c.Request.Context(), input)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, order)
}

func (h *Handler) GetOrder(c *gin.Context) {
	order, err := h.orderUseCase.GetOrder(c.Request.Context(), c.Param("id"))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, order)
}

func (h *Handler) UpdateOrderStatus(c *gin.Context) {
	var input domain.UpdateStatusInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	order, err := h.orderUseCase.UpdateStatus(c.Request.Context(), c.Param("id"), input.Status)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, order)
}
