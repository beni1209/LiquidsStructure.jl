### Types
abstract type ApproximationScheme{T} end

struct PercusYevick{T<:AbstractFloat} <: ApproximationScheme{T}
    η::T
    α::T
    β::T
    δ::T
end

struct MSA{T<:AbstractFloat} <: ApproximationScheme{T}
    η::T
    T′::T
    α₀::T
    α₁::T
    α₃::T
    β₁::T
    β₃::T
    a₁::T
    a₃::T
    b₁::T
    b₃::T
    py::PercusYevick{T}
end

struct RosenfeldFMT{T<:AbstractFloat} <: ApproximationScheme{T}
    η::T
    G::T
    A::T
    B::T
end

struct VerletWeis{T<:AbstractFloat} <: ApproximationScheme{T}
    py::PercusYevick{T}
    α::T
end


### Constructors
function PercusYevick(η::T) where {T<:AbstractFloat}
    η₀⁴ = @fastmath (1 - η)^4
    η₁² = (1 + 2η)^2
    η₂² = (2 +  η)^2

    α = -η₁² / η₀⁴
    β = 3η * η₂² / 2η₀⁴
    δ = -η * η₁² / 2η₀⁴

    return PercusYevick{T}(η, α, β, δ)
end

function MSA(T′::T, η::T, tol = sqrt(eps(T))) where {T<:AbstractFloat}
    κ  = dhs_msa_parameter(T′, η, tol)
    py = PercusYevick(η)

    ξ = κ * η

    ξ₁² = (1 - 2ξ)^2
    ξ₁⁴ = ξ₁² * ξ₁²
    ξ₂⁴ = (1 +  ξ)^4
    ξ₃² = (1 + 4ξ)^2

    r₁ = ξ₃² / ξ₁⁴
    r₂ = ξ₁² / ξ₂⁴
    r₃ = 8 * (1 + ξ)^2 / ξ₁⁴
    r₄ = (2 - ξ)^2 / ξ₂⁴

    α₀ = 2κ * (-r₁ + r₂)
    α₁ = 3ξ * κ * ( r₃ + r₄)
    α₃ = -ξ * κ * (2r₁ + r₂)
    β₁ = 3ξ * κ / 8 * (2r₃ - r₄)
    β₃ = -ξ * κ / 4 * (4r₁ - r₂)

    a₁ = 2 * (α₁ + 8β₁) / 3
    a₃ = 8 * (α₃ + 4β₃)
    b₁ = 2 * (α₁ - 4β₁) / 3
    b₃ = 8 * (α₃ - 2β₃)

    return MSA{T}(η, T′, α₀, α₁, α₃, β₁, β₃, a₁, a₃, b₁, b₃, py)
end

function RosenfeldFMT(η::T) where {T<:AbstractFloat}
    η² = η * η
    η³ = η² * η
    η⁴ = η³ * η
    η₋⁻¹ = 1 / (1 - η)
    η₋⁻² = η₋⁻¹ * η₋⁻¹
    Z  = (1 + 0.128η² + 0.027η³ + 0.06η⁴) * η₋⁻²
    Z′ = ((0.256η + 0.081η² + 0.24η³) * η₋⁻²) + (2Z * η₋⁻¹)
    χ = Z + η * Z′
    G = sqrt( Z′ / 2 )
    A = (1 + (2η - 1) * χ + 2η * G) / η
    B = ((1 - η) * χ - 1 - 3η * G) / η

    return RosenfeldFMT{T}(η, G, A, B)
end

function VerletWeis(η::T) where {T<:AbstractFloat}
    κ  = 1 - η / 16
    η′ = η * κ
    α  = ∛(κ)

    return VerletWeis{T}(PercusYevick(η′), α)
end
