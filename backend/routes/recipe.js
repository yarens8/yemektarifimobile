// Kullanıcının favori tariflerini getir
router.get('/favorites', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Kullanıcının favori tariflerini bul
    const favorites = await prisma.favorite.findMany({
      where: {
        userId: userId
      },
      include: {
        recipe: {
          include: {
            user: {
              select: {
                id: true,
                username: true,
                profileImage: true
              }
            },
            recipeImages: true,
            _count: {
              select: {
                favorites: true,
                comments: true
              }
            }
          }
        }
      }
    });

    // Tarif listesini oluştur
    const recipes = favorites.map(favorite => {
      const recipe = favorite.recipe;
      return {
        ...recipe,
        isFavorited: true,
        favoriteCount: recipe._count.favorites,
        commentCount: recipe._count.comments
      };
    });

    res.json({ recipes });
  } catch (error) {
    console.error('Favori tarifler getirilirken hata:', error);
    res.status(500).json({ error: 'Favori tarifler getirilirken bir hata oluştu' });
  }
}); 