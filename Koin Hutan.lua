local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Ganti "Coins" dengan nama folder koin yang benar di game tersebut
local coinFolder = workspace:FindFirstChild("Coins") or workspace:FindFirstChild("CoinFolder")

-- Variabel kontrol untuk menyalakan/mematikan magnet
local magnetActive = true 

print("Coin Magnet Aktif! Koin akan tertarik ke arahmu.")

-- Fungsi utama magnet
task.spawn(function()
    while magnetActive do
        if coinFolder then
            for _, coin in pairs(coinFolder:GetChildren()) do
                if coin:IsA("BasePart") or coin:IsA("MeshPart") then
                    -- Memindahkan koin tepat ke posisi karakter (HumanoidRootPart)
                    -- Kita beri sedikit offset (0, 2, 0) agar koin muncul di area badan
                    coin.CFrame = rootPart.CFrame * CFrame.new(0, 0, 0)
                    
                    -- Opsional: Menghilangkan tabrakan agar koin tidak mendorong karakter
                    coin.CanCollide = false
                end
            end
        end
        -- Jeda sangat singkat agar tidak lag tapi tetap terasa "real-time"
        task.wait(0.1) 
    end
end)

-- Reset referensi jika karakter mati/respawn
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    rootPart = newChar:WaitForChild("HumanoidRootPart")
end)
