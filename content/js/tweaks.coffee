@tweaks =
    projectileVelocity: 4
    projectileExplosiveness: 5
    missileOrigin: [88, 512 - 410]

    cannonPosition: [56, 512 - 448]
    cannonSize: [64, 256]   # size of base
    calibre: 6  # thickness of cannon
    cannonLength: 60
    cannonMinAngle: -.3
    cannonMaxAngle: Math.PI / 2

    gravity: -.02
    nextExplosiveness:
        5: 3
        3: 0
        #1: 0
        0: 0
    explosionRadius: 3
