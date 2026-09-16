import 'package:flutter/material.dart';

class SkeletonShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const SkeletonShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1300),
  });

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              stops: const [0.0, 0.5, 1.0],
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF8FAFC),
                Color(0xFFE2E8F0),
              ],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0.0, 0.0);
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry? margin;

  const SkeletonCircle({
    super.key,
    required this.size,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: const BoxDecoration(
        color: Color(0xFFE2E8F0),
        shape: BoxShape.circle,
      ),
    );
  }
}

class BerandaSkeleton extends StatelessWidget {
  const BerandaSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            color: const Color(0xFFCBD5E1),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  const SkeletonCircle(size: 44),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 140, height: 16, borderRadius: 4),
                        SizedBox(height: 6),
                        SkeletonBox(width: 90, height: 12, borderRadius: 4),
                      ],
                    ),
                  ),
                  const SkeletonCircle(size: 38),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonBox(width: 80, height: 14, borderRadius: 4),
                      SkeletonBox(width: 120, height: 24, borderRadius: 12),
                    ],
                  ),
                  SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(width: 100, height: 12, borderRadius: 4),
                            SizedBox(height: 8),
                            SkeletonBox(width: 50, height: 20, borderRadius: 4),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(width: 90, height: 12, borderRadius: 4),
                            SizedBox(height: 8),
                            SkeletonBox(width: 100, height: 20, borderRadius: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Expanded(child: SkeletonBox(height: 36, borderRadius: 8)),
                  SizedBox(width: 6),
                  Expanded(child: SkeletonBox(height: 36, borderRadius: 8)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 130, height: 16, borderRadius: 4),
                SizedBox(height: 6),
                SkeletonBox(width: 180, height: 12, borderRadius: 4),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonBox(width: 110, height: 20, borderRadius: 6),
                      SkeletonBox(width: 70, height: 14, borderRadius: 4),
                    ],
                  ),
                  SizedBox(height: 14),
                  SkeletonBox(width: 200, height: 18, borderRadius: 4),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 120, height: 12, borderRadius: 4),
                          SizedBox(height: 6),
                          SkeletonBox(width: 40, height: 16, borderRadius: 4),
                          SizedBox(height: 10),
                          SkeletonBox(width: 50, height: 12, borderRadius: 4),
                          SizedBox(height: 6),
                          SkeletonBox(width: 40, height: 16, borderRadius: 4),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 70, height: 22, borderRadius: 12),
                          SizedBox(height: 16),
                          SkeletonBox(width: 70, height: 12, borderRadius: 4),
                          SizedBox(height: 6),
                          SkeletonBox(width: 80, height: 16, borderRadius: 4),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
                  SkeletonBox(height: 42, borderRadius: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PekerjaanSayaSkeleton extends StatelessWidget {
  const PekerjaanSayaSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: Colors.white,
            child: const SafeArea(
              bottom: false,
              child: Center(
                child: SkeletonBox(width: 120, height: 18, borderRadius: 4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Expanded(child: SkeletonBox(height: 36, borderRadius: 8)),
                  SizedBox(width: 6),
                  Expanded(child: SkeletonBox(height: 36, borderRadius: 8)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SkeletonBox(width: 90, height: 32, borderRadius: 8),
                SizedBox(width: 8),
                SkeletonBox(width: 70, height: 32, borderRadius: 8),
                SizedBox(width: 8),
                SkeletonBox(width: 70, height: 32, borderRadius: 8),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 2,
              separatorBuilder: (_, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SkeletonBox(width: 100, height: 20, borderRadius: 6),
                          SkeletonBox(width: 60, height: 20, borderRadius: 10),
                        ],
                      ),
                      SizedBox(height: 12),
                      SkeletonBox(width: 180, height: 16, borderRadius: 4),
                      SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonBox(width: 90, height: 12, borderRadius: 4),
                              SizedBox(height: 4),
                              SkeletonBox(width: 60, height: 14, borderRadius: 4),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonBox(width: 80, height: 12, borderRadius: 4),
                              SizedBox(height: 4),
                              SkeletonBox(width: 70, height: 14, borderRadius: 4),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      SkeletonBox(height: 40, borderRadius: 8),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LaporanSkeleton extends StatelessWidget {
  const LaporanSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              color: Colors.white,
              child: const SafeArea(
                bottom: false,
                child: Center(
                  child: SkeletonBox(width: 130, height: 18, borderRadius: 4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SkeletonBox(width: 80, height: 32, borderRadius: 8),
                  SizedBox(width: 8),
                  SkeletonBox(width: 110, height: 32, borderRadius: 8),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 110, height: 12, borderRadius: 4),
                    SizedBox(height: 8),
                    SkeletonBox(width: 160, height: 22, borderRadius: 4),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonBox(width: 80, height: 12, borderRadius: 4),
                              SizedBox(height: 6),
                              SkeletonBox(width: 100, height: 16, borderRadius: 4),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonBox(width: 80, height: 12, borderRadius: 4),
                              SizedBox(height: 6),
                              SkeletonBox(width: 100, height: 16, borderRadius: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Expanded(child: SkeletonBox(height: 36, borderRadius: 8)),
                    SizedBox(width: 6),
                    Expanded(child: SkeletonBox(height: 36, borderRadius: 8)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SkeletonBox(width: 100, height: 20, borderRadius: 6),
                        SkeletonBox(width: 60, height: 20, borderRadius: 10),
                      ],
                    ),
                    SizedBox(height: 12),
                    SkeletonBox(width: 180, height: 16, borderRadius: 4),
                    SizedBox(height: 14),
                    SkeletonBox(height: 38, borderRadius: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilSkeleton extends StatelessWidget {
  const ProfilSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Center(child: SkeletonCircle(size: 76)),
            const SizedBox(height: 14),
            const SkeletonBox(width: 130, height: 18, borderRadius: 4),
            const SizedBox(height: 8),
            const SkeletonBox(width: 70, height: 22, borderRadius: 12),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 110, height: 16, borderRadius: 4),
                    SizedBox(height: 16),
                    SkeletonBox(width: 90, height: 12, borderRadius: 4),
                    SizedBox(height: 6),
                    SkeletonBox(width: 160, height: 16, borderRadius: 4),
                    SizedBox(height: 16),
                    SkeletonBox(width: 90, height: 12, borderRadius: 4),
                    SizedBox(height: 6),
                    SkeletonBox(width: 130, height: 16, borderRadius: 4),
                    SizedBox(height: 16),
                    SkeletonBox(width: 90, height: 12, borderRadius: 4),
                    SizedBox(height: 6),
                    SkeletonBox(width: 80, height: 16, borderRadius: 4),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SkeletonBox(height: 44, borderRadius: 8),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SkeletonBox(height: 44, borderRadius: 8),
            ),
          ],
        ),
      ),
    );
  }
}
