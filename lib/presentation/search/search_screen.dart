import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../injection_container.dart';
import 'bloc/search_bloc.dart';
import '../../widgets/surah_list_item.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SearchBloc _searchBloc = sl<SearchBloc>();

  @override
  void dispose() {
    _searchController.dispose();
    _searchBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _searchBloc,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => NavigatorService.goBack(),
          ),
          title: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: const InputDecoration(
              hintText: "Search Surah...",
              hintStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
            ),
            onChanged: (value) {
              _searchBloc.add(SearchQueryChanged(value));
            },
          ),
        ),
        body: BlocBuilder<SearchBloc, SearchState>(
          builder: (context, state) {
            if (state is SearchLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SearchLoaded) {
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: state.results.length,
                itemBuilder: (context, index) {
                  final surah = state.results[index];
                  // Use existing SurahListItem
                  return InkWell(
                    onTap: () {
                      NavigatorService.pushNamed(
                        AppRoutes.surahPage,
                        arguments: surah,
                      );
                    },
                    child: SurahListItem(
                      surahId: surah.id,
                      nameEnglish: surah.nameEnglish,
                      nameArabic: surah.nameArabic,
                    ),
                  );
                },
              );
            } else if (state is SearchEmpty) {
              return const Center(child: Text("No results found."));
            } else if (state is SearchError) {
              return Center(child: Text("Error: ${state.message}"));
            }
            // Initial state
            return const Center(child: Text("Type to search for a Surah."));
          },
        ),
      ),
    );
  }
}
