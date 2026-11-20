#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

// 圆角矩形的有向距离场：< 0 在内部，> 0 在外部。
// 复刻 liquid-glass-web 里的 roundedRectSDF。
static inline float sdRoundBox(float2 p, float2 b, float r) {
    float2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0f) + length(max(q, float2(0.0f))) - r;
}

// 液态玻璃。
//
// liquid-glass-web 的做法是：对每个像素算它到圆角边界的距离，靠近边界的像素把
// 采样点沿法线往中心推（scale 小于 1），于是边缘的内容被「压」进来 —— 这就是折射。
// 这里用同一套逻辑，只不过源图不是 backdrop-filter，而是本视图已经渲染好的材质层。
//
// position: 视图局部坐标（点）
// size:     视图尺寸
// radius:   圆角
// strength: 折射强度（边缘最大位移，单位点）
// edgeWidth:折射影响带宽度
[[ stitchable ]] half4 liquidGlass(float2 position,
                                   SwiftUI::Layer layer,
                                   float2 size,
                                   float radius,
                                   float strength,
                                   float edgeWidth) {
    float2 center = size * 0.5f;
    float2 p = position - center;

    float sdf = sdRoundBox(p, center, radius);
    float inside = -sdf;                                    // 内部为正
    float t = 1.0f - smoothstep(0.0f, max(edgeWidth, 1.0f), inside);
    t = t * t;                                              // 只让贴着边的一圈动

    float2 dir = normalize(p + float2(0.0001f, 0.0001f));
    float2 base = position - dir * t * strength;

    half4 color = layer.sample(base);

    // 色散：红蓝各偏一点，玻璃边缘才会有一线彩边
    float2 shift = dir * t * strength * 0.30f;
    color.r = layer.sample(base + shift).r;
    color.b = layer.sample(base - shift).b;

    // 材质在离屏渲染时可能拿不到背景，退化成透明 —— 给一层薄白兜底
    if (color.a < 0.04h) {
        color = half4(1.0h, 1.0h, 1.0h, 0.30h);
        color.rgb = half3(0.98h, 0.99h, 1.0h);
    }

    // 贴边高光：上半部分更亮，模拟光源在顶上
    float topBias = clamp(0.5f - p.y / max(size.y, 1.0f), 0.0f, 1.0f);
    float spec = smoothstep(0.40f, 1.0f, t) * (0.16f + 0.30f * topBias);
    color.rgb = saturate(color.rgb + half3(spec));

    return color;
}
