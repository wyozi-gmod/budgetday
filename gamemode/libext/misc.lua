function LerpColor(f, c1, c2)
	return Color(c1.r + (c2.r-c1.r)*f, c1.g + (c2.g-c1.g)*f, c1.b + (c2.b-c1.b)*f)
end
