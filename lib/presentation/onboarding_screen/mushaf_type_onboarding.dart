import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/quran_index/mushaf_types.dart';
import '../../core/utils/pref_utils.dart';
import '../mushaf_screen/mushaf_screen.dart';

/// First-time onboarding screen for selecting Mushaf type
/// Shown when user first opens the app
class MushafTypeOnboarding extends StatefulWidget {
  final VoidCallback onComplete;
  
  const MushafTypeOnboarding({
    super.key,
    required this.onComplete,
  });
  
  @override
  State<MushafTypeOnboarding> createState() => _MushafTypeOnboardingState();
}

class _MushafTypeOnboardingState extends State<MushafTypeOnboarding> {
  MushafType? _selectedType;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<_OnboardingPage> _pages = [];
  
  @override
  void initState() {
    super.initState();
    _initPages();
  }
  
  void _initPages() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    _pages.addAll([
      _OnboardingPage(
        title: isArabic ? 'مرحباً بك في حافظ' : 'Welcome to Hafiz',
        description: isArabic 
            ? 'تطبيقك المثالي لقراءة وحفظ وفهم القرآن الكريم'
            : 'Your perfect companion for reading, memorizing, and understanding the Quran',
        icon: Icons.menu_book,
        color: Colors.teal,
      ),
      _OnboardingPage(
        title: isArabic ? 'اختر نوع المصحف' : 'Choose Your Mushaf Type',
        description: isArabic
            ? 'اختر النمط الذي اعتدت عليه في قراءة القرآن الكريم. يمكنك تغيير هذا لاحقاً من الإعدادات.'
            : 'Select the style you are familiar with for reading the Quran. You can change this later in settings.',
        icon: Icons.layers,
        color: Colors.amber,
        isMushafSelector: true,
      ),
      _OnboardingPage(
        title: isArabic ? 'ابدأ رحلتك' : 'Start Your Journey',
        description: isArabic
            ? 'استمتع بقراءة القرآن مع ميزات متعددة للحفظ والتدبر'
            : 'Enjoy reading the Quran with multiple features for memorization and reflection',
        icon: Icons.play_circle_fill,
        color: Colors.green,
      ),
    ]);
  }
  
  void _completeOnboarding() {
    // Save selected Mushaf type
    if (_selectedType != null) {
      PrefUtils().setString('mushaf_type', _selectedType!.prefsKey);
    }
    
    // Mark onboarding as complete
    PrefUtils().setString('mushaf_onboarding_complete', 'true');
    
    widget.onComplete();
  }
  
  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    isArabic ? 'تخطي' : 'Skip',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
            
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) => _buildPage(_pages[index]),
              ),
            ),
            
            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Colors.teal
                          : Colors.grey[300],
                    ),
                  ),
                ),
              ),
            ),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(isArabic ? 'السابق' : 'Back'),
                    )
                  else
                    const SizedBox(width: 80),
                  
                  const Spacer(),
                  
                  ElevatedButton(
                    onPressed: _currentPage == 1 && _selectedType == null 
                        ? null 
                        : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32, 
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? (isArabic ? 'ابدأ' : 'Get Started')
                          : (isArabic ? 'التالي' : 'Next'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPage(_OnboardingPage page) {
    if (page.isMushafSelector) {
      return _buildMushafSelectorPage(page);
    }
    
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: page.color,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMushafSelectorPage(_OnboardingPage page) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 50,
              color: page.color,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            page.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Mushaf type options
          Expanded(
            child: ListView.builder(
              itemCount: allMushafTypes.length,
              itemBuilder: (context, index) {
                final type = allMushafTypes[index];
                final isSelected = type == _selectedType;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isSelected ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: isSelected
                        ? const BorderSide(color: Colors.teal, width: 2)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    onTap: () => setState(() => _selectedType = type),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.teal.withValues(alpha: 0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              type.icon,
                              color: isSelected ? Colors.teal : Colors.grey[600],
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isArabic ? type.displayName : type.displayNameEn,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.teal : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${type.totalPages} ${isArabic ? 'صفحة' : 'pages'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isArabic 
                                      ? _getArabicDesc(type)
                                      : type.description,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.teal,
                              size: 28,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  String _getArabicDesc(MushafType type) {
    switch (type) {
      case MushafType.madani:
        return 'الخط العثماني المستخدم في السعودية ومعظم الدول العربية';
      case MushafType.indoPak:
        return 'خط شبه القارة الهندية باكستان والهند وبنغلاديش';
      case MushafType.warsh:
        return 'خط ورش المستخدم في المغرب والجزائر وتونس';
    }
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isMushafSelector;
  
  _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isMushafSelector = false,
  });
}

/// Check if onboarding should be shown
bool shouldShowMushafOnboarding() {
  final completed = PrefUtils().getString('mushaf_onboarding_complete');
  return completed != 'true';
}
